import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permissions/permissions.dart';

import '../../providers/app_providers.dart';
import '../../providers/intake_providers.dart';
import 'intake_action_handler.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _controller = MobileScannerController();
  var _handled = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _ensureCameraPermission() async {
    final initializer = ref.read(appInitializerProvider);
    await initializer.requestPermission(AppPermission.camera);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        raw = value;
        break;
      }
    }
    if (raw == null) return;

    _handled = true;
    await _controller.stop();

    final resolver = ref.read(qrContentResolverProvider);
    final action = resolver.resolveQr(raw);
    await ref.read(qrHistoryStoreProvider).add(
          rawValue: raw,
          resolvedUrl: action.url,
        );
    refreshIntakeData(ref);

    if (!mounted) return;
    await IntakeActionHandler.handle(context, ref, action);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return UdmScaffold(
      title: 'Scan QR code',
      actions: [
        IconButton(
          icon: const Icon(Icons.flash_on_outlined),
          tooltip: 'Toggle flash',
          onPressed: () => unawaited(_controller.toggleTorch()),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _ensureCameraPermission(),
              builder: (context, snapshot) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: (capture) => unawaited(_onDetect(capture)),
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: UdmColors.signalCyan,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(UdmSpacing.lg),
            child: Text(
              'Point your camera at a download link or URL QR code.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

