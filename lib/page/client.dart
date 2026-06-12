import 'package:flutter/material.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';

class ClientList extends StatefulWidget {
  const ClientList({super.key});

  @override
  State<ClientList> createState() => _ClientListState();
}

class _ClientListState extends State<ClientList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBarDefault(hintText: 'cliente'),
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
                  title: 'Matheus Stevam',
                  text:
                      'Tel.: (21) 98456-2054\nE-mail: estevam28@gmail.com\nCPF: 566.281.684-98',
                  textInfo: 'Cód 001',
                  iconButton: IconButton(
                    onPressed: () => _showAddModal(),
                    icon: Icon(Icons.edit),
                    color: Colors.amber,
                  ),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModal() {
    showDialog(
      context: context,
      builder: (context) => ModalMod1(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextFieldMod1(labelText: 'Nome', width: 100),
                TextFieldMod1(labelText: 'CPF/CNPJ', width: 100),
              ],
            ),
            SizedBox(height: 10),
            TextFieldMod1(labelText: 'Email para contato'),
            SizedBox(height: 10),
            TextFieldMod1(labelText: 'Telefone para contato'),
          ],
        ),
      ),
    );
  }
}
