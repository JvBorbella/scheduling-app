import 'package:flutter/material.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/main.dart';

class Shedulings extends StatefulWidget {
  const Shedulings({super.key});

  @override
  State<Shedulings> createState() => _ShedulingsState();
}

class _ShedulingsState extends State<Shedulings> {
  bool notifyActivated = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBarDefault(hintText: 'agendamento'),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return CardList(
                  title: 'Hoje às 14:00',
                  text: 'Serviço(s): Corte de cabelo | Barba\nValor: R\$ 30,00\nCliente: Matheus Stevam',
                  textInfo: 'Nº 001',
                  iconButton: IconButton(
                  onPressed: () {
                    setState(() {
                      notifyActivated = !notifyActivated;
                    });
                  },
                  icon: notifyActivated
                      ? Icon(Icons.notifications_active, color: Colors.red)
                      : Icon(Icons.notifications_off, color: Colors.grey),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
