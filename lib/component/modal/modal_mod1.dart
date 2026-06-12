import 'package:flutter/material.dart';
import 'package:scheduling/component/button/button_mod1.dart';

class ModalMod1 extends StatefulWidget {
  final String? title, textButton;
  final dynamic content, onPressed;
  const ModalMod1({super.key, this.title, this.textButton, this.content, this.onPressed});

  @override
  State<ModalMod1> createState() => _ModalMod1State();
}

class _ModalMod1State extends State<ModalMod1> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      alignment: Alignment.center,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: widget.title != null ? Text(widget.title ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center) : null,
      content: widget.content,
      actions: [
        ButtonMod1(text: widget.textButton ?? 'Salvar', color: Colors.black, onPressed: widget.onPressed),
              SizedBox(height: 10),
              ButtonMod1(text: 'Fechar', color: Colors.red[900], onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}