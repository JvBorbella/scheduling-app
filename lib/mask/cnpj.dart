import 'package:flutter/services.dart';

class CustomCnpjAlfanumericoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Deixa apenas letras e números, removendo qualquer ponto/traço e deixa maiúsculo
    final text = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();

    // Limita a 14 caracteres (tamanho do CNPJ)
    final truncated = text.length > 14 ? text.substring(0, 14) : text;

    if (truncated.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');

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

String? unMasked(String value) {
  return value.replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
