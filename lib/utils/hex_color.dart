import 'package:flutter/material.dart';

Color hexToColor(String hexString) {
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', '').replaceFirst('0x', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.cyan; // Hata durumunda varsayılan renk
  }
}
