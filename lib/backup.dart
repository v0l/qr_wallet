import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'store.dart';

/// Export/import of the whole wallet as a single JSON file.
class Backup {
  static String _stamp() =>
      DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');

  /// Returns a human readable description of where the backup went.
  static Future<String> export() async {
    final json = CodeStore.instance.encode();
    final name = 'qr-wallet-backup-${_stamp()}.json';

    if (kIsWeb) {
      // Web: hand the bytes to the browser download flow via share_plus.
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(json),
              mimeType: 'application/json',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
        ),
      );
      return 'Backup downloaded';
    }

    // Desktop: ask for a save location.
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final location = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (location == null) return 'Export cancelled';
      await File(location.path).writeAsString(json, flush: true);
      return 'Saved to ${location.path}';
    }

    // Mobile: write to a temp file and open the share sheet.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(json, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [name]),
    );
    return 'Backup ready to share';
  }

  /// Returns the number of imported entries, or null if cancelled.
  static Future<int?> import() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          uniformTypeIdentifiers: ['public.json'],
          mimeTypes: ['application/json'],
        ),
      ],
    );
    if (file == null) return null;
    final raw = await file.readAsString();
    return CodeStore.instance.importBackup(raw);
  }
}
