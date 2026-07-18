import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/modals_crud/crud_scheduling.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:scheduling/style/color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Shedulings extends StatefulWidget {
  const Shedulings({super.key});

  @override
  State<Shedulings> createState() => _ShedulingsState();
}

class _ShedulingsState extends State<Shedulings> {
  List<bool> notifyActivated = [];
  List<dynamic> scheduleds = [];
  List<dynamic> orderItems = [];
  List<String> months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  List<int> daysMonths(int year, int month) {
    int lastDay = DateTime(year, month + 1, 0).day;
    return List<int>.generate(lastDay, (index) => index + 1);
  }

  SharedPreferences? prefs;

  Future<void> getPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      typeUI = prefs?.getInt('typeUI') ?? 0;
    });
  }

  int typeUI = 0; // 0 = list; 1 = calendar
  DateTime? selectedDay; // null = mês, não-null = planner
  String selectedMonth = DateTime.now().month.toString();

  Future<void> _listScheduleds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse(baseUrl + Endpoints.list),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-TENANT-ID': '4368297b-944d-4bc5-827c-333cfdf012f9',
        },
        body: jsonEncode({
          "q":
              "SELECT o.id, o.tenant_id, o.company_id, o.code, o.created_at AS scheduled_date, o.total_amount, p.name AS client, p.cpf, p.cnpj FROM orders o LEFT JOIN persons p ON p.id = o.customer_id WHERE o.tenant_id = '${prefs.getString('tenant_id')}'",
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] is List) {
          setState(() {
            scheduleds = data['results'];
          });
          _listOrderItems();
        } else if (data is List) {
          scheduleds = data;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _listOrderItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse(baseUrl + Endpoints.list),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-TENANT-ID': '4368297b-944d-4bc5-827c-333cfdf012f9',
        },
        body: jsonEncode({
          "q":
              "SELECT oi.id, oi.product_id, oi.code, oi.product_name, oi.quantity, oi.unit_price, oi.order_id FROM order_items oi",
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] is List) {
          setState(() {
            orderItems = data['results'];
          });
        } else if (data is List) {
          orderItems = data;
        }
        loadEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPrefs();
    _listScheduleds();
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      DateTime date;
      if (dateValue is int) {
        // Caso a API retorne timestamp em milissegundos
        date = DateTime.fromMillisecondsSinceEpoch(dateValue).toLocal();
      } else {
        String dateStr = dateValue.toString();
        // Se a data já vier no formato brasileiro (dd/MM/yyyy HH:mm)
        if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(dateStr)) {
          final splitStr = dateStr.split(' ');
          final dateParts = splitStr[0].split('/');
          final timeStr = splitStr.length > 1 ? ' ${splitStr[1]}' : '';
          // Converte para yyyy-MM-dd HH:mm para o DateTime.parse aceitar
          date = DateTime.parse(
            '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}$timeStr',
          );
        } else {
          // Tenta formato ISO padrão
          date = DateTime.parse(dateStr).toLocal();
        }
      }

      final now = DateTime.now();
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      if (isToday) {
        return 'Hoje às $hour:$minute';
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year.toString();
        return '$day/$month/$year às $hour:$minute';
      }
    } catch (e) {
      print('=== ERRO DE DATA ===\nValor Recebido: "$dateValue"\nErro: $e');
      return dateValue.toString();
    }
  }

  final EventsController controller = EventsController();

  void loadEvents() {
    controller.updateCalendarData((data) {
      data.clearAll();
      for (int i = 0; i < scheduleds.length; i++) {
        final schedule = scheduleds[i];

        final services = orderItems
            .where((item) => item['order_id'] == schedule['id'])
            .map((item) => item['product_name'])
            .join(', ');

        final dateStr = schedule['scheduled_date'];
        DateTime start = DateTime.now();

        if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(dateStr)) {
          final splitStr = dateStr.split(' ');
          final dateParts = splitStr[0].split('/');
          final timeStr = splitStr.length > 1 ? ' ${splitStr[1]}' : '';
          // Converte para yyyy-MM-dd HH:mm para o DateTime.parse aceitar
          start = DateTime.parse(
            '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}$timeStr',
          );
        } else {
          // Tenta formato ISO padrão
          start = DateTime.parse(dateStr).toLocal();
        }

        //final start = schedule['scheduled_date'];

        data.addEvents([
          Event(
            title: schedule['client'] ?? '',
            description: "${services.toString()}\n${schedule['total_amount']}",
            startTime: start,
            endTime: start.add(const Duration(hours: 1)),
            data: schedule,
            eventType: services,
          ),
        ]);
      }
    });
    setState(() {});
  }

  //bool notifyActivated = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: SearchBarDefault(hintText: 'agendamento')),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    typeUI = typeUI == 0 ? 1 : 0;
                    prefs.setInt('typeUI', typeUI!);
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: typeUI == 0
                ? ListView.builder(
                    itemCount: scheduleds.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      notifyActivated.add(true);
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ), // Margem externa mantida aqui
                        child: CardList(
                          title: _formatDate(
                            scheduleds[index]['scheduled_date'],
                          ),
                          text:
                              'Serviço(s): ${orderItems.where((item) => item['order_id'] == scheduleds[index]['id']).map((item) => item['product_name']).join(', ')}\nValor: R\$ ${scheduleds[index]['total_amount'].toString()}\nCliente: ${scheduleds[index]['client']}',
                          textInfo:
                              'Cód: ${scheduleds[index]['code'].toString()}',
                          iconButton: IconButton(
                            onPressed: () {
                              setState(() {
                                notifyActivated[index] =
                                    !notifyActivated[index];
                              });
                            },
                            icon: notifyActivated[index]
                                ? Icon(
                                    Icons.notifications_active,
                                    color: Colors.red,
                                  )
                                : Icon(
                                    Icons.notifications_off,
                                    color: Colors.grey,
                                  ),
                          ),
                          onLongPress: () async {
                            final serviceName = orderItems
                                .where(
                                  (item) =>
                                      item['order_id'] ==
                                      scheduleds[index]['id'],
                                )
                                .map((item) => item['product_name'])
                                .join(', ');

                            final Map<String, dynamic> data =
                                Map<String, dynamic>.from(scheduleds[index]);
                            data['service_name'] = serviceName;
                            data['scheduled_date'] =
                                scheduleds[index]['scheduled_date']; // manda formatado

                            final modal = await CrudScheduling.modalMod1(
                              context,
                              data['service_name'],
                              data['client'],
                              scheduleds[index]['scheduled_date'],
                              data['id'],
                              data['total_amount'],
                            );

                            showDialog(
                              context: context,
                              builder: (context) => modal,
                            ).then((_) {
                              _listScheduleds();
                            });
                          },
                        ),
                      );
                    },
                  )
                // : Column(
                //     children: [
                //       // Row(
                //       //   children: [
                //       //     DropdownButton(
                //       //       value: selectedMonth,
                //       //       dropdownColor: ColorsApp.primaryColor,
                //       //       items: months.map((month) {
                //       //         return DropdownMenuItem(
                //       //           child: Text(
                //       //             month,
                //       //             style: TextStyle(
                //       //               color: ColorsApp.secondaryColor,
                //       //             ),
                //       //           ),
                //       //           value: month,
                //       //         );
                //       //       }).toList(),
                //       //       onChanged: (value) {
                //       //         setState(() {
                //       //           selectedMonth = value!;
                //       //         });
                //       //       },
                //       //     ),
                //       //   ],
                //       // ),
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceAround,
                //         children: [
                //           Text(
                //             'Seg.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //           Text(
                //             'Ter.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //           Text(
                //             'Qua.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //           Text(
                //             'Qui.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //           Text(
                //             'Sex.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //           Text(
                //             'Sáb.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //           Text(
                //             'Dom.',
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: ColorsApp.secondaryColor,
                //             ),
                //           ),
                //         ],
                //       ),
                //       Expanded(
                //         child: GridView.builder(
                //           itemCount: daysMonths(
                //             DateTime.now().year,
                //             months.indexOf(selectedMonth),
                //           ).length,
                //           gridDelegate:
                //               const SliverGridDelegateWithFixedCrossAxisCount(
                //                 crossAxisCount: 7,
                //               ),
                //           itemBuilder: (context, index) {
                //             return Container(
                //               decoration: BoxDecoration(
                //                 border: Border.all(color: Colors.grey),
                //                 //borderRadius: BorderRadius.circular(8),
                //               ),
                //               child: Center(
                //                 child: Text(
                //                   daysMonths(
                //                     DateTime.now().year,
                //                     months.indexOf(selectedMonth),
                //                   )[index].toString(),
                //                   style: TextStyle(
                //                     fontWeight: FontWeight.bold,
                //                     fontSize: 8,
                //                     color: ColorsApp.secondaryColor,
                //                   ),
                //                 ),
                //               ),
                //             );
                //           },
                //         ),
                //       ),
                //     ],
                //   ),
                : selectedDay == null
                ? EventsMonths(
                    controller: controller,
                    daysParam: DaysParam(
                      onDayTapUp: (DateTime day) {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: ColorsApp.secondaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedDay = null;
                              });
                            },
                          ),
                          Text(
                            '${selectedDay!.day}/${selectedDay!.month}/${selectedDay!.year}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ColorsApp.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: EventsPlanner(
                          controller: controller,
                          initialDate: selectedDay,
                          daysShowed: 1,
                          dayParam: DayParam(
                            dayEventBuilder:
                                (event, height, width, heightPerMinute) {
                                  return DraggableEventWidget(
                                    event: event,
                                    height: height,
                                    width: width,
                                    onDragEnd:
                                        (
                                          columnIndex,
                                          exactStartDateTime,
                                          exactEndDateTime,
                                          roundStartDateTime,
                                          roundEndDateTime,
                                        ) => print(roundStartDateTime),
                                    child: DefaultDayEvent(
                                      height: height,
                                      width: width,
                                      title: event.title ?? '',
                                      description: event.description ?? '',
                                      onTap: () async {
                                        final schedule =
                                            event.data as Map<String, dynamic>;

                                        final modal =
                                            await CrudScheduling.modalMod1(
                                              context,
                                              event.eventType.toString(),
                                              schedule['client'],
                                              schedule['scheduled_date']
                                                  .toString(),
                                              schedule['id'].toString(),
                                              schedule['total_amount']
                                                  .toString(),
                                            );

                                        showDialog(
                                          context: context,
                                          builder: (context) => modal,
                                        ).then((_) {
                                          _listScheduleds();
                                        });
                                      },
                                    ),
                                  );
                                },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
