import 'package:flutter/material.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/style/color.dart';

class NotifyList extends StatefulWidget {
  const NotifyList({super.key});

  @override
  State<NotifyList> createState() => _NotifyListState();
}

class _NotifyListState extends State<NotifyList> {
  bool visibilityNotify1 = true;
  bool visibilityNotify2 = true;
  //bool notifyActivated = true;
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
              itemCount: 1,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ), // Margem externa mantida aqui
                      child: Visibility(
                        visible: visibilityNotify1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15), // Raio X
                          child: Dismissible(
                            key: const ValueKey(0),
                            direction: DismissDirection.startToEnd,
                            onDismissed: (right) {},
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: Colors.green, // Mesma cor do truque abaixo
                              child: Icon(
                                Icons.mark_email_read_rounded,
                                color: ColorsApp.primaryColor,
                              ),
                            ),
                            behavior: HitTestBehavior.deferToChild,
                            child: Container(
                              color: Colors
                                  .green, // Cor idêntica à do background do Dismissible
                              child: CardList(
                                title: 'Hoje às 14:00',
                                text:
                                    'Serviço(s): Corte de cabelo | Barba\nValor: R\$ 30,00\nCliente: Matheus Stevam',
                                textInfo: 'Nº 001',
                                iconButton: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Evita que a Row quebre o limite horizontal
                                  children: [
                                    IconButton(
                                      onPressed: () => setState(() {
                                        visibilityNotify1 = !visibilityNotify1;
                                      }),
                                      icon: const Icon(
                                        Icons.mark_email_read_rounded,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ), // Margem externa mantida aqui
                      child: Visibility(
                        visible: visibilityNotify2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Dismissible(
                            key: ValueKey(0),
                            onDismissed: (_) {},
                            background: Container(
                              height: 60,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.green,
                              ),
                              child: Icon(
                                Icons.mark_email_read_rounded,
                                color: ColorsApp.primaryColor,
                              ),
                            ),
                            // secondaryBackground: Container(
                            //   height: 60,
                            //   alignment: Alignment.centerRight,
                            //   padding: EdgeInsets.symmetric(horizontal: 20),
                            //   color: Colors.red,
                            //   child: Icon(Icons.delete, color: ColorsApp.primaryColor),
                            // ),
                            behavior: HitTestBehavior.deferToChild,
                            child: Container(
                              color: Colors
                                  .green, // Cor idêntica à do background do Dismissible
                              child: CardList(
                                title: 'Matheus Stevam',
                                text: 'Olá, bom dia!',
                                textInfo: '11:57',
                                iconButton: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: ColorsApp.secondaryColor,
                                      child: Text(
                                        '1',
                                        style: TextStyle(
                                          color: ColorsApp.primaryColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() {
                                        visibilityNotify2 = !visibilityNotify2;
                                      }),
                                      icon: Icon(
                                        Icons.mark_email_read_rounded,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
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
