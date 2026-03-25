import 'package:flutter/material.dart';

class ColorUtils {
  /// Genera sempre lo stesso colore per lo stesso nome
  static Color avatarColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final colors = [
      const Color(0xFF5B8DEF), // blu
      const Color(0xFF9B59B6), // viola
      const Color(0xFF27AE60), // verde
      const Color(0xFFE67E22), // arancio
      const Color(0xFFE74C3C), // rosso
      const Color(0xFF1ABC9C), // teal
      const Color(0xFFF39C12), // giallo
      const Color(0xFF2980B9), // blu scuro
    ];
    final index = name.codeUnits.fold<int>(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}
