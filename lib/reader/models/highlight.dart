import 'package:flutter/material.dart';

class Highlight {
  Highlight({required this.cfi, required this.color, required this.text});

  final String cfi;
  final Color color;
  final String text;

  Map<String, dynamic> toJson() {
    return {'cfi': cfi, 'color': color.value, 'text': text};
  }

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      cfi: json['cfi'] as String,
      color: Color(json['color'] as int? ?? Colors.yellow.value),
      text: json['text'] as String? ?? '',
    );
  }
}
