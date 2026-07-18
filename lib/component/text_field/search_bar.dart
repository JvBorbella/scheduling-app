import 'package:flutter/material.dart';
import 'package:scheduling/style/color.dart';

class SearchBarDefault extends StatefulWidget {
  final String? hintText;
  const SearchBarDefault({super.key, this.hintText});

  @override
  State<SearchBarDefault> createState() => _SearchBarDefaultState();
}

class _SearchBarDefaultState extends State<SearchBarDefault> {
  @override
  Widget build(BuildContext context) {
    return SearchBar(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      leading: Icon(Icons.search, color: ColorsApp.secondaryColor),
      trailing: [
        IconButton(
          onPressed: null,
          icon: Icon(Icons.filter_list_alt, color: ColorsApp.secondaryColor),
        ),
      ],
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStatePropertyAll(
        BorderSide(color: ColorsApp.secondaryColor, width: 1),
      ),
      shadowColor: WidgetStatePropertyAll(Colors.transparent),
      hintText: 'Pesquise pelo ${widget.hintText ?? '...'}',
      hintStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: ColorsApp.secondaryColor.withAlpha(75)),
      ),
      onChanged: (value) {
        // Lógica de busca aqui
      },
    );
  }
}
