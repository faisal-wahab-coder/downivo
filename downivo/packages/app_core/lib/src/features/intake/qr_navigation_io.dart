import 'package:flutter/material.dart';

import 'qr_scanner_screen.dart';

bool get qrScannerAvailable => true;

void openQrScanner(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => const QrScannerScreen(),
    ),
  );
}
