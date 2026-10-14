import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/card/dynamic_card.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/return/messenge.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/function/delete_function.dart';
import 'package:scheduling/function/search_function.dart';
import 'package:scheduling/mask/money.dart';
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

final GlobalKey<EventsMonthsState> _monthsKey = GlobalKey<EventsMonthsState>();
final GlobalKey<EventsPlannerState> _plannerKey =
    GlobalKey<EventsPlannerState>();

class _ShedulingsState extends State<Shedulings> {
  List<bool> notifyActivated = [];
  List<dynamic> scheduleds = [];
  List<dynamic> scheduleItems = [];
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
      querySchedules =
          """
        SELECT s.schedulings_id, s.tenant_id, s.code, DATE_FORMAT(s.scheduled_date, '%d/%m/%Y %H:%i') AS scheduled_date, s.total_amount, s.customer_id, p.name AS client, p.cpf_cnpj, p.phone, p.email, s.status 
        FROM schedulings s 
        LEFT JOIN persons p ON p.persons_id = s.customer_id 
        WHERE s.tenant_id = '${prefs?.getString('tenant_id')}' 
          AND s.is_deleted <> 1
          $filter
        ORDER BY s.scheduled_date DESC
      """;
    });
  }

  int typeUI = 0; // 0 = list; 1 = calendar
  DateTime? selectedDay; // null = mês, não-null = planner
  List<DateTime>? selectedRange; // null = mês, não-null = planner
  String selectedMonth = DateTime.now().month.toString();
  String filter = '';
  String querySchedules = '';

  TextEditingController customerController = TextEditingController();
  TextEditingController serviceController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  Future<void> _listScheduleds() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString("access_token") ?? prefs.getString("refresh_token");
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse(baseUrl + Endpoints.list),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-TENANT-ID': '${prefs.getString('tenant_id')}',
        },
        body: jsonEncode({"q": querySchedules}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] is List) {
          setState(() {
            scheduleds = data['results'];
          });
          _listScheduleItems();
        } else if (data is List) {
          scheduleds = data;
        }
      } else {
        Message.showReturnOverlay(
          context,
          Colors.red,
          Icons.error,
          response.body.toString(),
        );
      }
    } catch (e) {
      Message.showReturnOverlay(context, Colors.red, Icons.error, e.toString());
    }
  }

  Future<void> _listScheduleItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString("access_token") ?? prefs.getString("refresh_token");
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse(baseUrl + Endpoints.list),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-TENANT-ID': '${prefs.getString('tenant_id')}',
        },
        body: jsonEncode({
          "q":
              "SELECT ss.scheduling_services_id, ss.scheduling_id, ss.service_id, ss.code, ss.service_name, ss.quantity, ss.unit_price, ss.scheduling_id FROM scheduling_services ss WHERE ss.is_deleted <> 1 AND ss.tenant_id = '${prefs.getString('tenant_id')}'",
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] is List) {
          setState(() {
            scheduleItems = data['results'];
          });
        } else if (data is List) {
          scheduleItems = data;
        }
        loadEvents();
      } else {
        Message.showReturnOverlay(
          context,
          Colors.red,
          Icons.error,
          response.body.toString(),
        );
      }
    } catch (e) {
      Message.showReturnOverlay(context, Colors.red, Icons.error, e.toString());
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPrefs();
    _listScheduleds();
    _listScheduleItems();
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

        final services = scheduleItems
            .where(
              (item) => item['scheduling_id'] == schedule['schedulings_id'],
            )
            .map((item) => item['service_name'])
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

        data.addEvents([
          Event(
            title: schedule['client'] ?? '',
            description: "${services.toString()}\n${schedule['total_amount']}",
            startTime: start,
            endTime: start.add(const Duration(hours: 1)),
            data: schedule,
            eventType: scheduleItems
                .where(
                  (item) => item['scheduling_id'] == schedule['schedulings_id'],
                )
                .toList(),
          ),
        ]);
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RefreshIndicator(
            onRefresh: () => _listScheduleds(),
            child: Column(
              spacing: 10,
              children: [
                SearchBarDefault(
                  hintText: 'agendamento',
                  controller: searchController,
                  onPressedSearch: () async {
                    scheduleds = await search(
                      searchController.text,
                      scheduleds,
                    );
                    setState(() {});
                  },
                  onPressedFilter: () async {
                    if (typeUI == 1) {
                      DateTime? picked = await showOmniDateTimePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1600),
                        lastDate: DateTime(2100),
                        is24HourMode: false,
                        isForce2Digits: true,
                        minutesInterval: 1,
                        secondsInterval: 1,
                      );
                      if (picked != null) {
                        selectedDay = picked;
                        setState(() {});
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              bool scheduled = true;
                              bool aproved = false;
                              //bool deleted = false;
                              return ModalMod1(
                                title: 'Filtros',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 10,
                                  children: [
                                    TextFieldMod1(
                                      controller: TextEditingController(
                                        text: selectedRange == null
                                            ? DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(DateTime.now())
                                            : '${DateFormat('dd/MM/yyyy HH:mm').format(selectedRange!.first)} até ${DateFormat('dd/MM/yyyy HH:mm').format(selectedRange!.last)}',
                                      ),
                                      labelText: 'Data e horário',
                                      suffixIcon: IconButton(
                                        onPressed: () async {
                                          List<DateTime>? picked =
                                              await showOmniDateTimeRangePicker(
                                                transitionDuration: Duration(
                                                  milliseconds: 200,
                                                ),
                                                context: context,
                                              );
                                          if (picked != null) {
                                            selectedRange = picked;
                                            setState(() {});
                                          }
                                        },
                                        icon: Icon(Icons.date_range),
                                      ),
                                    ),
                                    TextFieldMod1(
                                      controller: customerController,
                                      labelText: 'CLiente',
                                    ),
                                    TextFieldMod1(
                                      controller: serviceController,
                                      labelText: 'Serviços',
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: scheduled,
                                          onChanged: (value) {
                                            setState(() {
                                              scheduled = value!;
                                            });
                                          },
                                        ),
                                        Text(
                                          'Em aberto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: ColorsApp.secondaryColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        Checkbox(
                                          value: aproved,
                                          onChanged: (value) {
                                            setState(() {
                                              aproved = value!;
                                            });
                                          },
                                        ),
                                        Text(
                                          'Concluído',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: ColorsApp.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                textButton: 'Filtrar',
                                // Exemplo de refatoração do callback onPressed no botão "Filtrar":
                                onPressed: () async {
                                  List<String> statusConditions = [];
                                  if (scheduled)
                                    statusConditions.add("'scheduled'");
                                  if (aproved)
                                    statusConditions.add("'aproved'");

                                  String statusClause = '';
                                  if (statusConditions.isNotEmpty) {
                                    statusClause =
                                        " AND s.status IN (${statusConditions.join(',')})";
                                  }

                                  String dateClause = '';
                                  if (selectedRange != null &&
                                      selectedRange!.length >= 2) {
                                    final startStr = DateFormat(
                                      'yyyy-MM-dd HH:mm:ss',
                                    ).format(selectedRange!.first);
                                    final endStr = DateFormat(
                                      'yyyy-MM-dd HH:mm:ss',
                                    ).format(selectedRange!.last);
                                    dateClause =
                                        " AND s.scheduled_date BETWEEN '$startStr' AND '$endStr'";
                                  }

                                  String customerSearch = customerController
                                      .text
                                      .replaceAll("'", "''");
                                  String customerClause = '';
                                  if (customerSearch.isNotEmpty) {
                                    customerClause =
                                        " AND (p.name LIKE '%$customerSearch%' OR p.cpf_cnpj LIKE '%$customerSearch%' OR p.email LIKE '%$customerSearch%' OR p.phone LIKE '%$customerSearch%')";
                                  }

                                  setState(() {
                                    filter =
                                        "$dateClause$statusClause$customerClause";

                                    // Atualiza a query SQL completa com os novos filtros
                                    querySchedules =
                                        """
      SELECT s.schedulings_id, s.tenant_id, s.code, DATE_FORMAT(s.scheduled_date, '%d/%m/%Y %H:%i') AS scheduled_date, s.total_amount, s.customer_id, p.name AS client, p.cpf_cnpj, p.phone, p.email, s.status 
      FROM schedulings s 
      LEFT JOIN persons p ON p.persons_id = s.customer_id 
      WHERE s.tenant_id = '${prefs?.getString('tenant_id')}' 
        AND s.is_deleted <> 1
        $filter
      ORDER BY s.scheduled_date DESC
    """;
                                  });

                                  await _listScheduleds();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    }
                  },
                ),
                ButtonMod1(
                  onPressed: () async {
                    await prefs?.setInt('typeUI', typeUI == 0 ? 1 : 0);
                    setState(() {
                      typeUI = typeUI == 0 ? 1 : 0;
                    });
                  },
                  color: ColorsApp.secondaryColor,
                  colorLabel: ColorsApp.primaryColor,
                  text:
                      'Modo de visualização: ${typeUI == 0 ? "Lista" : "Agenda"}',
                ),
                Expanded(
                  child: typeUI == 0
                      ? ListView.builder(
                          itemCount: scheduleds.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            notifyActivated.add(true);
                            return DynamicCard(
                              right: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ModalMod1(
                                    title: 'Finalizar agendamento',
                                    content: Column(
                                      spacing: 10.0,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Serviço(s): ',
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                            Text(
                                              scheduleItems
                                                  .where(
                                                    (item) =>
                                                        item['scheduling_id'] ==
                                                        scheduleds[index]['schedulings_id'],
                                                  )
                                                  .map(
                                                    (item) =>
                                                        item['service_name'],
                                                  )
                                                  .join(', '),
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Valor: R\$ ',
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                            Text(
                                              maskMoney(
                                                scheduleds[index]['total_amount'],
                                              ).toString(),
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Cliente: ',
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                            Text(
                                              scheduleds[index]['client'],
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Forma de pagamento: ',
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                            Text(
                                              scheduleds[index]['payment_type'] ??
                                                  '',
                                              style: TextStyle(
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextFieldMod1(
                                          controller: _descriptionController,
                                          maxLines: 5,
                                          labelText: 'Observação',
                                        ),
                                      ],
                                    ),
                                    onPressed: () async {
                                      final baseUrl = dotenv.env['BASE_URL']!;
                                      final token =
                                          prefs?.getString("access_token") ??
                                          prefs?.getString("refresh_token");
                                      try {
                                        final response = await http.post(
                                          Uri.parse(baseUrl + Endpoints.edit),
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                            'X-TENANT-ID':
                                                '${prefs?.getString('tenant_id')}',
                                          },
                                          body: jsonEncode({
                                            "tabela": "schedulings",
                                            "id":
                                                scheduleds[index]['schedulings_id'],
                                            "values": {"status": 'aproved'},
                                          }),
                                        );
                                        if (response.statusCode == 200) {
                                          Message.showReturnOverlay(
                                            context,
                                            Colors.green,
                                            Icons.check,
                                            'Agendamento finalizado com sucesso!',
                                          );
                                          _listScheduleds();
                                        } else {
                                          Message.showReturnOverlay(
                                            context,
                                            Colors.red,
                                            Icons.error,
                                            response.body.toString(),
                                          );
                                        }
                                      } catch (e) {
                                        Message.showReturnOverlay(
                                          context,
                                          Colors.red,
                                          Icons.error,
                                          e.toString(),
                                        );
                                      }
                                    },
                                    textButton: 'Finalizar agendamento',
                                  ),
                                );
                              },
                              left: () =>
                                  deleteData(
                                    scheduleds[index],
                                    context,
                                    'schedulings',
                                  ).then((_) {
                                    _listScheduleds();
                                  }),
                              colorRight: Colors.green,
                              colorLeft: Colors.red,
                              remove: false,
                              child: CardList(
                                title: _formatDate(
                                  scheduleds[index]['scheduled_date'],
                                ),
                                text:
                                    'Serviço(s): ${scheduleItems.where((item) => item['scheduling_id'] == scheduleds[index]['schedulings_id']).map((item) => item['service_name']).join(', ')}\nValor: R\$ ${maskMoney(scheduleds[index]['total_amount'].toString())}\nCliente: ${scheduleds[index]['client']}',
                                textInfo:
                                    'Cód: ${scheduleds[index]['code'].toString()}\n${scheduleds[index]['status']}',
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
                                  final Map<String, dynamic> data =
                                      Map<String, dynamic>.from(
                                        scheduleds[index],
                                      );
                                  data['service_name'] = scheduleItems
                                      .where(
                                        (item) =>
                                            item['scheduling_id'] ==
                                            scheduleds[index]['schedulings_id'],
                                      )
                                      .toList();
                                  data['scheduled_date'] =
                                      scheduleds[index]['scheduled_date']; // manda formatado);

                                  final modal = await CrudScheduling.modalMod1(
                                    context,
                                    scheduleItems
                                        .where(
                                          (item) =>
                                              item['scheduling_id'] ==
                                              scheduleds[index]['schedulings_id'],
                                        )
                                        .toList(),
                                    data['client'],
                                    data['phone'],
                                    data['email'],
                                    data['cpf_cnpj'],
                                    data['customer_id'],
                                    scheduleds[index]['scheduled_date'],
                                    data['schedulings_id'],
                                    data['total_amount'].toString(),
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
                      : selectedDay == null
                      ? EventsMonths(
                          key: _monthsKey,
                          controller: controller,
                          weekParam: WeekParam(
                            headerDayTextColor: (dayOfMonth) =>
                                ColorsApp.secondaryColor,
                            headerDayBuilder: (dayOfMonth) {
                              final day = dayOfMonth;
                              final List dayWeek = [
                                "Seg",
                                "Ter",
                                "Qua",
                                "Qui",
                                "Sex",
                                "Sáb",
                                "Dom",
                              ];
                              return Center(
                                child: Text(
                                  dayWeek[day - 1],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorsApp.secondaryColor,
                                  ),
                                ),
                              );
                            },
                            startOfWeekDay: 1,
                          ),
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
                                  '${DateFormat('EEEE', 'pt_BR').format(selectedDay!)}, ${DateFormat('dd').format(selectedDay!)}/${DateFormat('MM').format(selectedDay!)}/${selectedDay!.year}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorsApp.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: EventsPlanner(
                                key: _plannerKey,
                                controller: controller,
                                onDayChange: (DateTime day) {
                                  setState(() {
                                    selectedDay = day;
                                  });
                                },
                                initialDate: selectedDay,
                                daysShowed: 1,
                                fullDayParam: FullDayParam(
                                  fullDayEventsBarVisibility: false,
                                ),
                                daysHeaderParam: DaysHeaderParam(
                                  daysHeaderVisibility: false,
                                ),
                                timesIndicatorsParam: TimesIndicatorsParam(
                                  timesIndicatorsWidth: 50,
                                ),
                                offTimesParam: OffTimesParam(
                                  offTimesAllDaysRanges: [
                                    OffTimeRange(
                                      TimeOfDay(hour: 0, minute: 0),
                                      TimeOfDay(hour: 0, minute: 0),
                                    ),
                                    OffTimeRange(
                                      TimeOfDay(hour: 24, minute: 0),
                                      TimeOfDay(hour: 24, minute: 0),
                                    ),
                                  ],
                                  offTimesColor: Color(0xFFF4F4F4),
                                ),
                                dayParam: DayParam(
                                  onSlotMinutesRound: 30,
                                  dayColor: ColorsApp
                                      .primaryColor, //Colors.grey[100],
                                  todayColor: ColorsApp.primaryColor,
                                  onSlotTap:
                                      (
                                        columnIndex,
                                        exactDateTime,
                                        roundDateTime,
                                      ) async {
                                        final modal =
                                            await CrudScheduling.modalMod1(
                                              context,
                                              null,
                                              '',
                                              roundDateTime.toString(),
                                              '',
                                              '',
                                              '',
                                              '',
                                              '',
                                              '',
                                            );

                                        showDialog(
                                          context: context,
                                          builder: (context) => modal,
                                        ).then((_) {
                                          _listScheduleds();
                                        });
                                      },
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
                                            color: ColorsApp.secondaryColor,
                                            textColor: ColorsApp.primaryColor,
                                            height: height,
                                            width: width,
                                            title: event.title ?? '',
                                            description:
                                                event.description ?? '',
                                            descriptionFontSize: 8,
                                            onTap: () async {
                                              final schedule =
                                                  event.data
                                                      as Map<String, dynamic>;

                                              final modal =
                                                  await CrudScheduling.modalMod1(
                                                    context,
                                                    event.eventType,
                                                    schedule['client'],
                                                    schedule['phone'],
                                                    schedule['email'],
                                                    schedule['cpf_cnpj'],
                                                    schedule['customer_id'],
                                                    schedule['scheduled_date']
                                                        .toString(),
                                                    schedule['schedulings_id']
                                                        .toString(),
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
          ),
        ),
        if (typeUI == 1)
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: ColorsApp.secondaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                clipBehavior: Clip.none,
                mini: true,
                elevation: 0,
                backgroundColor: ColorsApp.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  final now = DateTime.now();
                  if (selectedDay == null) {
                    // Se estiver na visualização mensal (EventsMonths), faz scroll para o mês atual
                    _monthsKey.currentState?.jumpToDate(now);
                  } else {
                    // Se estiver no planejador diário (EventsPlanner), atualiza o estado e navega para hoje
                    setState(() {
                      selectedDay = now;
                    });
                    _plannerKey.currentState?.jumpToDate(now);
                  }
                },
                child: Text(
                  'Hoje',
                  style: TextStyle(color: ColorsApp.primaryColor),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
