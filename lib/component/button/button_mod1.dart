import 'package:flutter/material.dart';
import 'package:scheduling/style/color.dart';

class ButtonMod1 extends StatefulWidget {
  final String? text;
  final Color? color;
  final Color? colorLabel;
  final double? width;
  final dynamic onPressed;
  const ButtonMod1({
    super.key,
    this.text,
    this.color,
    this.colorLabel,
    this.width,
    this.onPressed,
  });

  @override
  State<ButtonMod1> createState() => _ButtonMod1State();
}

class _ButtonMod1State extends State<ButtonMod1> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          backgroundColor: widget.color ?? Colors.blue[300],
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: ColorsApp.secondaryColor),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          widget.text ?? '',
          style: TextStyle(
            color: widget.colorLabel ?? ColorsApp.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
