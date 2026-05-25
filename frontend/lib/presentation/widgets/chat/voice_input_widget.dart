import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/voice_service.dart';

enum _VoiceInputState { idle, recording, processing, error }

class VoiceInputWidget extends ConsumerStatefulWidget {
  final Function(String transcript) onTranscript;
  final VoidCallback onCancel;

  const VoiceInputWidget({
    super.key,
    required this.onTranscript,
    required this.onCancel,
  });

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  _VoiceInputState _state = _VoiceInputState.idle;
  String _errorMessage = '';
  int _recordingSeconds = 0;
  Timer? _timer;
  late final AnimationController _animationController;
  late final AudioRecorder _recorder;
  late final VoiceService _voiceService;

  static const int _barCount = 5;
  static const double _barMinHeight = 4.0;
  static const double _barMaxHeight = 24.0;
  static const double _barWidth = 3.0;
  static const double _barSpacing = 2.0;
  static const String _recordingPath = '/tmp/recording.m4a';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _recorder = AudioRecorder();
    _voiceService = VoiceService();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission needed')),
          );
        }
        return;
      }

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordingPath,
      );

      _recordingSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordingSeconds++);
        }
      });

      _animationController.repeat(reverse: true);

      setState(() => _state = _VoiceInputState.recording);
    } catch (e) {
      setState(() {
        _state = _VoiceInputState.error;
        _errorMessage = 'Failed to start recording';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      _animationController.stop();

      final path = await _recorder.stop();
      if (path == null) {
        setState(() {
          _state = _VoiceInputState.error;
          _errorMessage = 'Recording failed';
        });
        return;
      }

      setState(() => _state = _VoiceInputState.processing);
      await _transcribeAudio(path);
    } catch (e) {
      setState(() {
        _state = _VoiceInputState.error;
        _errorMessage = 'Failed to stop recording';
      });
    }
  }

  Future<void> _transcribeAudio(String path) async {
    try {
      final transcript = await _voiceService.transcribeAudio(path);
      if (mounted) {
        widget.onTranscript(transcript);
        setState(() => _state = _VoiceInputState.idle);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _VoiceInputState.error;
          _errorMessage = 'Transcription failed';
        });
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _timer?.cancel();
      _animationController.stop();
      await _recorder.stop();
    } catch (_) {
      // Ignore errors during cancel
    }
    if (mounted) {
      widget.onCancel();
      setState(() => _state = _VoiceInputState.idle);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _VoiceInputState.idle:
        return _buildIdleState();
      case _VoiceInputState.recording:
        return _buildRecordingState();
      case _VoiceInputState.processing:
        return _buildProcessingState();
      case _VoiceInputState.error:
        return _buildErrorState();
    }
  }

  Widget _buildIdleState() {
    return GestureDetector(
      onTap: _startRecording,
      child: const Icon(
        Icons.mic_none,
        size: 22,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildRecordingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _cancelRecording,
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildWaveform()),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error,
                ),
                child: const Center(
                  child: Icon(
                    Icons.stop,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatDuration(_recordingSeconds),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_barCount, (index) {
            final offset = index * (pi / _barCount);
            final animValue = sin(
              _animationController.value * pi + offset,
            ).abs();
            final height = _barMinHeight +
                (_barMaxHeight - _barMinHeight) * animValue;

            return Container(
              margin: EdgeInsets.only(
                right: index < _barCount - 1 ? _barSpacing : 0,
              ),
              width: _barWidth,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.persian,
                borderRadius: BorderRadius.circular(_barWidth / 2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProcessingState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.persian,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Transcribing...',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _errorMessage,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.error,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => setState(() => _state = _VoiceInputState.idle),
          child: const Icon(
            Icons.refresh,
            size: 18,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
