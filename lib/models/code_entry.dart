import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

/// Supported symbologies, mapped onto the `barcode` package types.
enum CodeFormat {
  qr('QR Code', BarcodeType.QrCode),
  aztec('Aztec', BarcodeType.Aztec),
  dataMatrix('Data Matrix', BarcodeType.DataMatrix),
  pdf417('PDF417', BarcodeType.PDF417),
  code128('Code 128', BarcodeType.Code128),
  code39('Code 39', BarcodeType.Code39),
  code93('Code 93', BarcodeType.Code93),
  ean13('EAN-13', BarcodeType.CodeEAN13),
  ean8('EAN-8', BarcodeType.CodeEAN8),
  upcA('UPC-A', BarcodeType.CodeUPCA),
  upcE('UPC-E', BarcodeType.CodeUPCE),
  itf('ITF', BarcodeType.Itf),
  codabar('Codabar', BarcodeType.Codabar);

  const CodeFormat(this.label, this.barcodeType);

  final String label;
  final BarcodeType barcodeType;

  /// True for 2D symbologies (rendered square-ish, no human readable text).
  bool get isMatrix => const {
        CodeFormat.qr,
        CodeFormat.aztec,
        CodeFormat.dataMatrix,
        CodeFormat.pdf417,
      }.contains(this);

  Barcode get barcode => Barcode.fromType(barcodeType);

  static CodeFormat fromName(String? name) => CodeFormat.values.firstWhere(
        (f) => f.name == name,
        orElse: () => CodeFormat.qr,
      );
}

/// A stored loyalty card / ticket / code.
class CodeEntry {
  CodeEntry({
    required this.id,
    required this.label,
    required this.data,
    required this.format,
    required this.color,
    this.icon,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String data;
  final CodeFormat format;

  /// ARGB colour used for the card tile.
  final int color;

  /// Optional emoji shown on the tile.
  final String? icon;
  final String? note;
  final DateTime createdAt;

  Color get colorValue => Color(color);

  CodeEntry copyWith({
    String? label,
    String? data,
    CodeFormat? format,
    int? color,
    String? icon,
    String? note,
  }) =>
      CodeEntry(
        id: id,
        label: label ?? this.label,
        data: data ?? this.data,
        format: format ?? this.format,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'data': data,
        'format': format.name,
        'color': color,
        if (icon != null) 'icon': icon,
        if (note != null) 'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CodeEntry.fromJson(Map<String, dynamic> json) => CodeEntry(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        data: json['data'] as String? ?? '',
        format: CodeFormat.fromName(json['format'] as String?),
        color: (json['color'] as num?)?.toInt() ?? 0xFF3F51B5,
        icon: json['icon'] as String?,
        note: json['note'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Palette offered when creating/editing a card.
const kCardPalette = <int>[
  0xFF1E88E5,
  0xFF43A047,
  0xFFE53935,
  0xFF8E24AA,
  0xFFF4511E,
  0xFF00897B,
  0xFF3949AB,
  0xFF6D4C41,
  0xFF546E7A,
  0xFFD81B60,
];

const kCardIcons = <String>[
  '🛒', '☕', '🍔', '⛽', '💊', '📚', '🎬', '✈️', '🏋️', '🐾', '🎟️', '💳',
];
