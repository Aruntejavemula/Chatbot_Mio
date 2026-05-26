import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';

import 'api_service.dart';

class TtsService {
  AudioPlayer? _player;
  String? _currentId;

  Future<void> speak(String text, String messageId) async {
    if (_currentId == messageId && (_player?.playing ?? false)) {
      await stop();
      return;
    }

    await stop();
    _currentId = messageId;

    try {
      _player ??= AudioPlayer();
      final truncated = text.length > 4096 ? text.substring(0, 4096) : text;

      final dio = Dio();
      final response = await dio.post<List<int>>(
        '/voice/tts',
        data: {'text': truncated, 'voice': 'alloy'},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) return;

      final bytes = Uint8List.fromList(response.data!);
      final source = AudioSource.uri(
        Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
      );
      await _player!.setAudioSource(source);
      await _player!.play();
      _currentId = null;
    } catch (e) {
      _currentId = null;
      rethrow;
    }
  }

  bool isPlaying(String messageId) {
    return _currentId == messageId && (_player?.playing ?? false);
  }

  Future<void> stop() async {
    await _player?.stop();
    _currentId = null;
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
