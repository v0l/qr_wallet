import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/code_entry.dart';
import '../store.dart';

/// Create or edit a card. Pass [existing] to edit, or [initialData]/
/// [initialFormat] to pre-fill from a scan.
class EditScreen extends StatefulWidget {
  const EditScreen({
    super.key,
    this.existing,
    this.initialData,
    this.initialFormat,
  });

  final CodeEntry? existing;
  final String? initialData;
  final CodeFormat? initialFormat;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _data;
  late final TextEditingController _note;
  late CodeFormat _format;
  late int _color;
  String? _icon;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _data = TextEditingController(text: e?.data ?? widget.initialData ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _format = e?.format ?? widget.initialFormat ?? CodeFormat.qr;
    _color = e?.color ??
        kCardPalette[DateTime.now().microsecond % kCardPalette.length];
    _icon = e?.icon;
  }

  @override
  void dispose() {
    _label.dispose();
    _data.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validateForFormat(String value) {
    try {
      _format.barcode.verify(value);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('BarcodeException: ', '');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final store = CodeStore.instance;
    final note = _note.text.trim();
    if (widget.existing != null) {
      await store.update(widget.existing!.copyWith(
        label: _label.text.trim(),
        data: _data.text.trim(),
        format: _format,
        color: _color,
        icon: _icon,
        note: note.isEmpty ? null : note,
      ));
    } else {
      await store.add(CodeEntry(
        id: const Uuid().v4(),
        label: _label.text.trim(),
        data: _data.text.trim(),
        format: _format,
        color: _color,
        icon: _icon,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final valid = _validateForFormat(_data.text.trim()) == null &&
        _data.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add card' : 'Edit card'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Tesco Clubcard',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Label is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CodeFormat>(
              initialValue: _format,
              decoration: const InputDecoration(
                labelText: 'Format',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final f in CodeFormat.values)
                  DropdownMenuItem(value: f, child: Text(f.label)),
              ],
              onChanged: (f) => setState(() => _format = f ?? _format),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _data,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Code data',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Code data is required';
                return _validateForFormat(s);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Colour'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in kCardPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.white : Colors.black26,
                          width: _color == c ? 3 : 1,
                        ),
                      ),
                      child: _color == c
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('None'),
                  selected: _icon == null,
                  onSelected: (_) => setState(() => _icon = null),
                ),
                for (final i in kCardIcons)
                  ChoiceChip(
                    label: Text(i, style: const TextStyle(fontSize: 18)),
                    selected: _icon == i,
                    onSelected: (_) => setState(() => _icon = i),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            if (valid)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarcodeWidget(
                    barcode: _format.barcode,
                    data: _data.text.trim(),
                    drawText: !_format.isMatrix,
                    height: _format.isMatrix ? 180 : 90,
                    errorBuilder: (context, error) => Text(error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
