import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart' as zx;

import 'models/code_entry.dart';

/// Result of a scan / image import, before the user labels it.
class ScanResult {
  ScanResult(this.data, this.format);

  final String data;
  final CodeFormat format;
}

/// Platforms where `mobile_scanner` can drive a live camera preview.
bool get cameraScanSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Platforms where `mobile_scanner` can decode a still image (all formats).
bool get nativeImageDecodeSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Map a scanner result format onto our storage/render format.
CodeFormat mapScannerFormat(BarcodeFormat f) {
  switch (f) {
    case BarcodeFormat.code128:
      return CodeFormat.code128;
    case BarcodeFormat.code39:
      return CodeFormat.code39;
    case BarcodeFormat.code93:
      return CodeFormat.code93;
    case BarcodeFormat.codabar:
      return CodeFormat.codabar;
    case BarcodeFormat.dataMatrix:
      return CodeFormat.dataMatrix;
    case BarcodeFormat.ean13:
      return CodeFormat.ean13;
    case BarcodeFormat.ean8:
      return CodeFormat.ean8;
    case BarcodeFormat.itf2of5:
    case BarcodeFormat.itf2of5WithChecksum:
    case BarcodeFormat.itf14:
      return CodeFormat.itf;
    case BarcodeFormat.upcA:
      return CodeFormat.upcA;
    case BarcodeFormat.upcE:
      return CodeFormat.upcE;
    case BarcodeFormat.pdf417:
      return CodeFormat.pdf417;
    case BarcodeFormat.aztec:
      return CodeFormat.aztec;
    default:
      return CodeFormat.qr;
  }
}

/// Pure-Dart QR decode from image bytes.
///
/// Used on platforms where `mobile_scanner` cannot analyze still images
/// (desktop + web). QR only — that covers screenshots of most loyalty apps.
ScanResult? decodeQrFromBytes(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  // Downscale huge screenshots a bit; keeps decode fast without hurting rate.
  final src = image.width > 2000 ? img.copyResize(image, width: 2000) : image;

  final pixels = Int32List(src.width * src.height);
  var i = 0;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      pixels[i++] =
          (0xFF << 24) | (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
    }
  }

  final source = zx.RGBLuminanceSource(src.width, src.height, pixels);
  final reader = zx.QRCodeReader();
  final hints = zx.DecodeHints()..put(zx.DecodeHintType.tryHarder);
  for (final bitmap in [
    zx.BinaryBitmap(zx.HybridBinarizer(source)),
    zx.BinaryBitmap(zx.GlobalHistogramBinarizer(source)),
  ]) {
    try {
      final result = reader.decode(bitmap, hints: hints);
      if (result.text.isNotEmpty) {
        return ScanResult(result.text, CodeFormat.qr);
      }
    } catch (_) {
      // try next binarizer
    }
  }
  return null;
}
