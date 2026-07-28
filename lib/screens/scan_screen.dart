import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../scan_utils.dart';

/// Scan a code with the camera (where available) or import one from an image
/// file / screenshot. Pops with a [ScanResult].
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.imageOnly = false});

  /// Skip the camera entirely and go straight to file import.
  final bool imageOnly;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? _controller;
  bool _handled = false;
  bool _busy = false;

  bool get _useCamera => !widget.imageOnly && cameraScanSupported;

  @override
  void initState() {
    super.initState();
    if (_useCamera) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _finish(ScanResult result) {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      const typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
        uniformTypeIdentifiers: ['public.image'],
        mimeTypes: ['image/*'],
      );
      final file = await openFile(acceptedTypeGroups: const [typeGroup]);
      if (file == null || !mounted) return;

      ScanResult? result;

      // Native decoders handle every symbology; use them where available.
      if (nativeImageDecodeSupported) {
        try {
          final controller = _controller ?? MobileScannerController();
          final capture = await controller.analyzeImage(file.path);
          final b = capture?.barcodes.firstOrNull;
          if (b != null && (b.rawValue?.isNotEmpty ?? false)) {
            result = ScanResult(b.rawValue!, mapScannerFormat(b.format));
          }
          if (_controller == null) await controller.dispose();
        } catch (e) {
          debugPrint('analyzeImage failed: $e');
        }
      }

      // Pure-Dart QR fallback (desktop, web, or native miss).
      result ??= decodeQrFromBytes(await file.readAsBytes());

      if (!mounted) return;
      if (result != null) {
        _finish(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No code found in that image')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importButton = FilledButton.icon(
      onPressed: _busy ? null : _pickImage,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.image_outlined),
      label: const Text('Import from image'),
    );

    if (!_useCamera) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import code')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, size: 72),
                const SizedBox(height: 16),
                Text(
                  cameraScanSupported
                      ? 'Pick an image containing a code.'
                      : 'Camera scanning is not available on this platform.\n'
                          'Pick a screenshot or photo containing a QR code.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                importButton,
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan code'),
        actions: [
          IconButton(
            tooltip: 'Torch',
            onPressed: () => _controller?.toggleTorch(),
            icon: const Icon(Icons.flashlight_on),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => _controller?.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final b = capture.barcodes.firstOrNull;
              if (b != null && (b.rawValue?.isNotEmpty ?? false)) {
                _finish(ScanResult(b.rawValue!, mapScannerFormat(b.format)));
              }
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Camera unavailable (${error.errorCode.name}).\n\n'
                  'You can still import a code from an image.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: importButton,
            ),
          ),
        ],
      ),
    );
  }
}
