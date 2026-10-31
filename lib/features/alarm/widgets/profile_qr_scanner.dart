import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';

class ProfileQrScanner extends StatefulWidget {
  const ProfileQrScanner({super.key, required this.expectedData});

  final String expectedData;

  @override
  State<ProfileQrScanner> createState() => _ProfileQrScannerState();
}

class _ProfileQrScannerState extends State<ProfileQrScanner> {
  bool _hasScanned = false;
  bool _hasInvalidScan = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    var foundCode = false;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;
      foundCode = true;
      if (rawValue == widget.expectedData) {
        _hasScanned = true;
        Navigator.of(context).pop(true);
        return;
      }
    }

    if (foundCode && !_hasInvalidScan && mounted) {
      setState(() => _hasInvalidScan = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppUiTokens.cardRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan your Profile QR',
              style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              _hasInvalidScan
                  ? 'That QR code does not match your profile. Try again.'
                  : 'Show the QR from your Profile on another screen.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: _hasInvalidScan ? cs.error : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppUiTokens.cardRadiusMedium,
                ),
                child: MobileScanner(onDetect: _onDetect),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
