import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/code_entry.dart';

/// Simple JSON backed store for [CodeEntry] items.
///
/// On native platforms the whole list lives in `<app support dir>/codes.json`
/// and writes are atomic (temp file + rename) so a crash mid-save can't
/// corrupt the wallet. On web the same JSON blob is kept in local storage via
/// `shared_preferences`.
class CodeStore extends ChangeNotifier {
  CodeStore._();

  static final CodeStore instance = CodeStore._();

  static const _fileName = 'codes.json';
  static const _prefsKey = 'qr_wallet_codes';
  static const _schemaVersion = 1;

  List<CodeEntry> _codes = [];
  bool _loaded = false;

  List<CodeEntry> get codes => List.unmodifiable(_codes);
  bool get loaded => _loaded;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  Future<void> load() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_prefsKey);
        if (raw != null) _codes = _decode(raw);
      } else {
        final f = await _file();
        if (await f.exists()) {
          _codes = _decode(await f.readAsString());
        }
      }
    } catch (e) {
      debugPrint('CodeStore.load failed: $e');
      _codes = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, encode());
    } else {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(encode(), flush: true);
      await tmp.rename(f.path);
    }
    notifyListeners();
  }

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'version': _schemaVersion,
    'codes': _codes.map((c) => c.toJson()).toList(),
  });

  static List<CodeEntry> _decode(String raw) {
    final decoded = jsonDecode(raw);
    final list = decoded is Map<String, dynamic>
        ? (decoded['codes'] as List? ?? [])
        : (decoded as List);
    return list
        .cast<Map<String, dynamic>>()
        .map(CodeEntry.fromJson)
        .toList(growable: true);
  }

  Future<void> add(CodeEntry entry) async {
    _codes.insert(0, entry);
    await _persist();
  }

  Future<void> update(CodeEntry entry) async {
    final i = _codes.indexWhere((c) => c.id == entry.id);
    if (i == -1) return;
    _codes[i] = entry;
    await _persist();
  }

  Future<void> delete(String id) async {
    _codes.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    _codes.insert(newIndex, _codes.removeAt(oldIndex));
    await _persist();
  }

  CodeEntry? byId(String id) {
    for (final c in _codes) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Merge a backup file. Entries with an existing id are skipped.
  /// Returns the number of imported entries.
  Future<int> importBackup(String raw) async {
    final incoming = _decode(raw);
    final existing = _codes.map((c) => c.id).toSet();
    final fresh = incoming.where((c) => !existing.contains(c.id)).toList();
    _codes.addAll(fresh);
    await _persist();
    return fresh.length;
  }
}
