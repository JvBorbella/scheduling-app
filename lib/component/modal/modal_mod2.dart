import 'package:flutter/material.dart';
import 'package:scheduling/style/color.dart';

class ModalMod2 extends StatefulWidget {
  final String? title, textButton;
  final dynamic content, onPressed;
  const ModalMod2({
    super.key,
    this.title,
    this.textButton,
    this.content,
    this.onPressed,
  });

  @override
  State<ModalMod2> createState() => _ModalMod2State();
}

class _ModalMod2State extends State<ModalMod2> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorsApp.primaryColor,
      alignment: Alignment.center,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: widget.title != null
          ? Text(
              widget.title ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ColorsApp.secondaryColor,
              ),
              textAlign: TextAlign.center,
            )
          : null,
      content: widget.content,
    );
  }
}
