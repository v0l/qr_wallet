import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../store.dart';
import 'edit_screen.dart';

/// Fullscreen presentation of a single code.
///
/// Forces max screen brightness (restored on exit) and a white background so
/// scanners read the code reliably.
class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key, required this.id});

  final String id;

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  @override
  void initState() {
    super.initState();
    _maxBrightness();
  }

  Future<void> _maxBrightness() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('setApplicationScreenBrightness failed: $e');
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('resetApplicationScreenBrightness failed: $e');
    }
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CodeStore.instance,
      builder: (context, _) {
        final entry = CodeStore.instance.byId(widget.id);
        if (entry == null) {
          return const Scaffold(body: Center(child: Text('Card deleted')));
        }
        return Theme(
          data: ThemeData.light(useMaterial3: true),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              title: Text(entry.label,
                  style: const TextStyle(color: Colors.black)),
              actions: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditScreen(existing: entry),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: BarcodeWidget(
                          barcode: entry.format.barcode,
                          data: entry.data,
                          color: Colors.black,
                          backgroundColor: Colors.white,
                          drawText: !entry.format.isMatrix,
                          width: entry.format.isMatrix
                              ? MediaQuery.of(context).size.width * 0.8
                              : MediaQuery.of(context).size.width * 0.9,
                          height: entry.format.isMatrix
                              ? MediaQuery.of(context).size.width * 0.8
                              : 140,
                          errorBuilder: (context, error) => Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SelectableText(
                        entry.data,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (entry.note != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          entry.note!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        entry.format.label,
                        style: const TextStyle(color: Colors.black38),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
