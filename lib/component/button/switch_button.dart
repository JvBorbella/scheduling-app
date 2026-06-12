import 'package:flutter/material.dart';

class SwitchButton extends StatefulWidget {
  final bool isChecked;
  final dynamic onChanged;
  const SwitchButton({super.key, this.isChecked = false, this.onChanged});

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
        value: isChecked ?? false,
        activeTrackColor: Colors.black,
        inactiveThumbColor: Colors.grey,
        onChanged: widget.onChanged
      ),
    );
  }
}
