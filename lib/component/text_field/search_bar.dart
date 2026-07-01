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
      leading: Icon(Icons.search, color: ColorsApp.primaryColor),
      trailing: [
        IconButton(
          onPressed: null,
          icon: Icon(Icons.filter_list_alt, color: ColorsApp.primaryColor),
        ),
      ],
      backgroundColor: WidgetStatePropertyAll(
        Color.fromARGB(255, 216, 216, 216),
      ),
      shadowColor: WidgetStatePropertyAll(Colors.transparent),
      hintText: 'Pesquise pelo ${widget.hintText ?? '...'}',
      hintStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
      onChanged: (value) {
        // Lógica de busca aqui
      },
    );
  }
}
