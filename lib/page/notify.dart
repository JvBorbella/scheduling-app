import 'package:flutter/material.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/text_field/search_bar.dart';

class NotifyList extends StatefulWidget {
  const NotifyList({super.key});

  @override
  State<NotifyList> createState() => _NotifyListState();
}

class _NotifyListState extends State<NotifyList> {
  bool notifyActivated = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBarDefault(hintText: 'agendamento'),
          SizedBox(height: 20),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Dismissible(
                  key: ValueKey(0),
                  onDismissed: (_) {},
                  background: Container(
                    height: 60,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.green,
                    ),
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                    ),
                  ),
                  // secondaryBackground: Container(
                  //   height: 60,
                  //   alignment: Alignment.centerRight,
                  //   padding: EdgeInsets.symmetric(horizontal: 20),
                  //   color: Colors.red,
                  //   child: Icon(Icons.delete, color: Colors.white),
                  // ),
                  behavior: HitTestBehavior.deferToChild,
                  child: Column(
                    children: [
                      CardList(
                        title: 'Hoje às 14:00',
                        text:
                            'Serviço(s): Corte de cabelo | Barba\nValor: R\$ 30,00\nCliente: Matheus Stevam',
                        textInfo: 'Nº 001',
                        iconButton: Row(
                          children: [
                            IconButton(
                              onPressed: null,
                              icon: Icon(
                                Icons.mark_email_read_rounded,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardList(
                        title: 'Matheus Stevam',
                        text: 'Olá, bom dia!',
                        textInfo: '11:57',
                        iconButton: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.black,
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: null,
                              icon: Icon(
                                Icons.mark_email_read_rounded,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    // Expanded(
    //   child: ListView.builder(
    //     itemCount: 3,
    //     itemBuilder: (context, index) {
    //       return CardList(
    //         title: 'Hoje às 14:00',
    //         text: 'Serviço(s): Corte de cabelo | Barba\nValor: R\$ 30,00\nCliente: Matheus Stevam',
    //         textInfo: 'Nº 001',
    //         iconButton: IconButton(
    //         onPressed: () {
    //           setState(() {
    //             notifyActivated = !notifyActivated;
    //           });
    //         },
    //         icon: notifyActivated
    //             ? Icon(Icons.notifications_active, color: Colors.red)
    //             : Icon(Icons.notifications_off, color: Colors.grey),
    //       ));
    //     },
    //   ),
    // ),
  }
}
