import 'package:flutter/material.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/page/chat.dart';

class MessengeList extends StatefulWidget {
  const MessengeList({super.key});

  @override
  State<MessengeList> createState() => _MessengeListState();
}

class _MessengeListState extends State<MessengeList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBarDefault(hintText: 'chat'),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ), // Margem externa mantida aqui
                  child: CardList(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Chat()),
                    ),
                    title: 'Matheus Stevam',
                    text: 'Olá, bom dia!',
                    textInfo: '11:57',
                    iconButton: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black,
                      child: Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
