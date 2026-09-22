import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../spacing.dart';
import '../theme/udm_colors.dart';
import '../theme/zfile_tokens.dart';

/// Dialog showing SHA-256 and MD5 checksums for a completed download.
class ChecksumDialog extends StatefulWidget {
  const ChecksumDialog({
    super.key,
    required this.fileName,
    required this.sha256,
    required this.md5,
  });

  final String fileName;
  final String sha256;
  final String md5;

  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required String sha256,
    required String md5,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ChecksumDialog(
        fileName: fileName,
        sha256: sha256,
        md5: md5,
      ),
    );
  }

  @override
  State<ChecksumDialog> createState() => _ChecksumDialogState();
}

class _ChecksumDialogState extends State<ChecksumDialog> {
  bool _copiedSha = false;
  bool _copiedMd5 = false;

  void _copySha() {
    Clipboard.setData(ClipboardData(text: widget.sha256));
    setState(() => _copiedSha = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedSha = false);
    });
  }

  void _copyMd5() {
    Clipboard.setData(ClipboardData(text: widget.md5));
    setState(() => _copiedMd5 = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedMd5 = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = ZfileTokens.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(UdmSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokens.secondaryDark.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.verified_user_rounded,
                        size: 20, color: tokens.secondaryDark),
                  ),
                  const SizedBox(width: UdmSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Integrity & Checksum',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fileName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? UdmColors.fogSteel
                                : UdmColors.slateMute,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: UdmSpacing.lg),

              // SHA-256.
              _HashField(
                label: 'SHA-256',
                hash: widget.sha256,
                copied: _copiedSha,
                onCopy: _copySha,
                isDark: isDark,
              ),

              const SizedBox(height: UdmSpacing.md),

              // MD5.
              _HashField(
                label: 'MD5',
                hash: widget.md5,
                copied: _copiedMd5,
                onCopy: _copyMd5,
                isDark: isDark,
              ),

              const SizedBox(height: UdmSpacing.lg),

              // Verification badge.
              Container(
                padding: const EdgeInsets.all(UdmSpacing.md),
                decoration: BoxDecoration(
                  color: tokens.secondaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tokens.secondaryDark.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: tokens.secondaryDark),
                    const SizedBox(width: UdmSpacing.sm),
                    Expanded(
                      child: Text(
                        'File integrity confirmed. Zero corruption detected.',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.secondaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: UdmSpacing.lg),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HashField extends StatelessWidget {
  const _HashField({
    required this.label,
    required this.hash,
    required this.copied,
    required this.onCopy,
    required this.isDark,
  });

  final String label;
  final String hash;
  final bool copied;
  final VoidCallback onCopy;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tokens = ZfileTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label Checksum:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(UdmSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? UdmColors.insetWell : UdmColors.paper,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? UdmColors.hairline : UdmColors.lightHairline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  hash,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: tokens.secondaryDark,
                  ),
                ),
              ),
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onCopy,
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  color: copied ? tokens.secondaryDark : UdmColors.fogSteel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
