import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scheduling/style/color.dart';

class TextFieldMod1 extends StatefulWidget {
  final String? labelText;
  final bool obscureText, readOnly;
  final dynamic suffix, suffixIcon;
  final double? width;
  final int? maxLines;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  const TextFieldMod1({
    super.key,
    this.labelText,
    this.obscureText = false,
    this.readOnly = false,
    this.suffix,
    this.suffixIcon,
    this.width,
    this.maxLines,
    this.controller,
    this.inputFormatters,
    this.onChanged,
    this.keyboardType,
  });

  @override
  State<TextFieldMod1> createState() => _TextFieldMod1State();
}

class _TextFieldMod1State extends State<TextFieldMod1> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines ?? 1,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.labelText ?? '',
            labelStyle: TextStyle(color: Colors.grey, fontSize: 10),
            fillColor: Colors.grey[350],
            filled: true,
            suffix: widget.suffix,
            suffixIcon: widget.suffixIcon != null
                ? IconButton(onPressed: null, icon: widget.suffixIcon)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: ColorsApp.secondaryColor,
                width: 3.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
