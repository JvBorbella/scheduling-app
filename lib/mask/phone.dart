import 'package:flutter/services.dart';

class PhoneMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();

    final truncated = text.length > 11 ? text.substring(0, 11) : text;

    if (truncated.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i == 2) buffer.write('.');
      if (i == 6) buffer.write('-');
      buffer.write(truncated[i]);
    }

    final string = buffer.toString();

    // Mantém o cursor no fim do texto
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
