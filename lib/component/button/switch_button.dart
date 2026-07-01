import 'package:flutter/material.dart';
import 'package:scheduling/style/color.dart';

class SwitchButton extends StatefulWidget {
  final bool isChecked;
  final Function(bool?)? onChanged;
  const SwitchButton({super.key, required this.isChecked, this.onChanged});

  @override
  State<SwitchButton> createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  bool? isChecked;

  @override
  initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.7, // Fator de escala (1.0 é o tamanho padrão)
      child: Switch(
        value: widget.isChecked,
        activeThumbColor: ColorsApp.primaryColor,
        activeTrackColor: ColorsApp.secondaryColor,
        onChanged: widget.onChanged,
      ),
    );
  }
}
