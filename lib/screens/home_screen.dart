import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../backup.dart';
import '../models/code_entry.dart';
import '../scan_utils.dart';
import '../store.dart';
import 'edit_screen.dart';
import 'scan_screen.dart';
import 'view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _scan(BuildContext context, {bool imageOnly = false}) async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(builder: (_) => ScanScreen(imageOnly: imageOnly)),
    );
    if (result == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditScreen(
          initialData: result.data,
          initialFormat: result.format,
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (value) {
      case 'export':
        final msg = await Backup.export();
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      case 'import':
        try {
          final n = await Backup.import();
          if (n != null) {
            messenger.showSnackBar(
              SnackBar(content: Text('Imported $n card(s)')),
            );
          }
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Import failed: $e')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Wallet'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export backup')),
              PopupMenuItem(value: 'import', child: Text('Import backup')),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: CodeStore.instance,
        builder: (context, _) {
          final store = CodeStore.instance;
          if (!store.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.codes.isEmpty) {
            return _EmptyState(onScan: () => _scan(context));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: store.codes.length,
            onReorder: store.reorder,
            itemBuilder: (context, i) {
              final entry = store.codes[i];
              return _CodeTile(
                key: ValueKey(entry.id),
                entry: entry,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ViewScreen(id: entry.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'manual',
            tooltip: 'Enter manually',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditScreen()),
            ),
            child: const Icon(Icons.keyboard),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'image',
            tooltip: 'Import from image',
            onPressed: () => _scan(context, imageOnly: true),
            child: const Icon(Icons.image_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: () => _scan(context),
            icon: Icon(
                cameraScanSupported ? Icons.qr_code_scanner : Icons.add),
            label: Text(cameraScanSupported ? 'Scan' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({super.key, required this.entry, required this.onTap});

  final CodeEntry entry;
  final VoidCallback onTap;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${entry.label}"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await CodeStore.instance.delete(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _confirmDelete(context),
        child: Row(
          children: [
            Container(width: 8, height: 84, color: entry.colorValue),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: entry.icon != null
                    ? Text(entry.icon!, style: const TextStyle(fontSize: 30))
                    : BarcodeWidget(
                        barcode: entry.format.barcode,
                        data: entry.data,
                        drawText: false,
                        color: Colors.black,
                        padding: const EdgeInsets.all(4),
                        errorBuilder: (_, _) => const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.label,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.format.label} · ${entry.data}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.drag_handle, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wallet_outlined, size: 80),
            const SizedBox(height: 16),
            Text('No cards yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Scan a loyalty card, import a screenshot, '
              'or enter a code manually.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.add),
              label: const Text('Add your first card'),
            ),
          ],
        ),
      ),
    );
  }
}
