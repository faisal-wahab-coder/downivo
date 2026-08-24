import 'package:content_intake/content_intake.dart';
import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'intake_action_handler.dart';

/// Prompts the user when clipboard or share content is detected.
Future<void> showIntakeActionSheet(
  BuildContext context,
  WidgetRef ref,
  IntakeAction action,
) async {
  if (Navigator.maybeOf(context) == null) return;

  final next = await showModalBottomSheet<IntakeAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UdmSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _titleFor(action),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: UdmSpacing.sm),
              if (action.url != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: PlatformBadge(
                    label: SocialPlatform.fromUri(
                          Uri.tryParse(action.url!) ?? Uri(),
                        )?.label ??
                        (action.label ?? 'Link'),
                  ),
                ),
                const SizedBox(height: UdmSpacing.sm),
              ],
              Text(
                action.url ?? action.text ?? action.label ?? '',
                style: Theme.of(sheetContext).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UdmSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, action),
                child: Text(_primaryLabel(action)),
              ),
              if (action.type == IntakeActionType.download) ...[
                const SizedBox(height: UdmSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    IntakeAction(
                      type: IntakeActionType.openInBrowser,
                      url: action.url,
                    ),
                  ),
                  child: const Text('Open in browser instead'),
                ),
              ],
              const SizedBox(height: UdmSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (next == null || !context.mounted) return;
  await IntakeActionHandler.handle(context, ref, next);
}

String _titleFor(IntakeAction action) => switch (action.type) {
      IntakeActionType.download => 'Download detected',
      IntakeActionType.openInBrowser => 'Open link',
      IntakeActionType.importFiles => 'Import shared files',
      IntakeActionType.showText => 'Shared content',
    };

String _primaryLabel(IntakeAction action) => switch (action.type) {
      IntakeActionType.download => 'Download',
      IntakeActionType.openInBrowser => 'Open in browser',
      IntakeActionType.importFiles => 'Import files',
      IntakeActionType.showText => 'View text',
    };
