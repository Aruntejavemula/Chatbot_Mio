import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/connector_model.dart';
import '../../../data/services/connector_service.dart';

const Map<String, List<String>> _connectorCapabilities = {
  'google_drive': [
    'Access and search files in your Google Drive',
    'Read document contents for context',
    'List recently modified files',
    'Organize and reference shared drives',
  ],
  'gmail': [
    'Read and search your emails',
    'Summarize email threads',
    'Draft email responses',
    'Access email attachments',
  ],
  'google_calendar': [
    'View upcoming events and meetings',
    'Create and update calendar events',
    'Check availability and scheduling conflicts',
    'Send meeting invitations',
  ],
  'notion': [
    'Search and read Notion pages',
    'Create and update pages and databases',
    'Access workspace content for context',
    'Organize notes and documentation',
  ],
  'github': [
    'Access repositories and code',
    'Read and create issues',
    'Review pull requests',
    'Search code across repositories',
  ],
  'slack': [
    'Read and search messages',
    'Send messages to channels',
    'Access shared files and links',
    'List channels and members',
  ],
  'jira': [
    'View and create issues',
    'Update issue status and assignments',
    'Search across projects',
    'Access sprint and board data',
  ],
  'linear': [
    'View and create issues',
    'Update issue status and priority',
    'Search across teams and projects',
    'Access cycle and roadmap data',
  ],
  'zapier': [
    'Trigger automated workflows',
    'Connect to 5000+ apps via Zaps',
    'Send data to external services',
    'Receive webhook notifications',
  ],
};

class ConnectorDetailScreen extends ConsumerStatefulWidget {
  final String connectorName;

  const ConnectorDetailScreen({super.key, required this.connectorName});

  @override
  ConsumerState<ConnectorDetailScreen> createState() =>
      _ConnectorDetailScreenState();
}

class _ConnectorDetailScreenState
    extends ConsumerState<ConnectorDetailScreen> {
  final ConnectorService _service = ConnectorService();
  ConnectorModel? _connector;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConnector();
  }

  Future<void> _loadConnector() async {
    try {
      final connectors = await _service.getConnectors();
      if (mounted) {
        final match = connectors.where((c) => c.name == widget.connectorName);
        setState(() {
          _connector = match.isNotEmpty ? match.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connect() async {
    setState(() => _isActionLoading = true);
    try {
      final url = await _service.getAuthUrl(widget.connectorName);
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open auth page')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isActionLoading = true);
    try {
      await _service.disconnect(widget.connectorName);
      await _loadConnector();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to disconnect')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _connector?.label ?? '',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _connector == null
              ? Center(
                  child: Text(
                    'Connector not found',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(isDark),
                      const SizedBox(height: 16),
                      _buildConnectButton(isDark),
                      const SizedBox(height: 24),
                      _buildCapabilitiesList(isDark),
                      const SizedBox(height: 24),
                      _buildPrivacyNote(isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.extension_outlined,
              size: 28,
              color: AppColors.persian,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _connector!.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _connector!.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_connector!.isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Connected',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectButton(bool isDark) {
    if (_connector!.isConnected) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isActionLoading ? null : _disconnect,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isActionLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Disconnect',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isActionLoading ? null : _connect,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.persian,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isActionLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Connect',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildCapabilitiesList(bool isDark) {
    final capabilities =
        _connectorCapabilities[widget.connectorName] ?? [];

    if (capabilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capabilities',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...capabilities.map((capability) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      capability,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPrivacyNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBgTertiary.withValues(alpha: 0.5)
            : AppColors.bgTertiary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your data is encrypted and only accessed when you explicitly ask Mio to use this connector. You can disconnect at any time.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
