import 'package:flutter/services.dart';

class CepMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();

    final truncated = text.length > 8 ? text.substring(0, 8) : text;

    if (truncated.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(truncated[i]);
    }

    final string = buffer.toString();

    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
