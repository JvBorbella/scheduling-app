import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/card/dynamic_card.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/function/delete_function.dart';
import 'package:scheduling/function/edit_function.dart';
import 'package:scheduling/function/filter_function.dart';
import 'package:scheduling/function/log_request_function.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotifyList extends StatefulWidget {
  const NotifyList({super.key});

  @override
  State<NotifyList> createState() => _NotifyListState();
}

class _NotifyListState extends State<NotifyList> {
  List<dynamic> notifications = [];
  bool visibilityNotify1 = true;
  bool visibilityNotify2 = true;

  @override
  void initState() {
    super.initState();
    getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () => getNotifications(),
        strokeWidth: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              SearchBarDefault(
                hintText: 'agendamento',
                onPressedFilter: () => showDynamicFilterModal(
                  context: context,
                  table: 'notifications',
                  columns: notifications[0]['metadata'],
                ).then((value) {
                  if (value != null) {
                    setState(() {
                      notifications = value['results'];
                    });
                  }
                }),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    bool remove = false;
                    var notify = notifications[index];
                    return Column(
                      children: [
                        DynamicCard(
                          colorRight: Colors.green,
                          colorLeft: Colors.red,
                          remove: remove,
                          child: CardList(
                            title: '${notify['title']}',
                            text: '${notify['message']}\nAgendado para ${notify['schedules_at'] != null ? notify['schedules_at'] : ''}',
                            textInfo: notify['is_read'] == 1 ? 'Lida ✅' : '',
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
                          right: () async {
                            remove = false;
                            var response = await editData(
                              notify,
                              {"is_read": 1},
                              context,
                              'notifications',
                            );
                            if (response) {
                              getNotifications();
                            }
                          },
                          left: () async {
                            remove = true;
                            var response = await deleteData(
                              notify,
                              context,
                              'notifications',
                            );
                            if (response) {
                              setState(() {
                                notifications.removeAt(index);
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString("access_token") ?? prefs.getString("refresh_token");
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    final uri = Uri.parse(baseUrl + Endpoints.list);
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'X-TENANT-ID': prefs.getString("tenant_id")!,
    };
    final body = {
      "q":
          "SELECT * FROM notifications n WHERE n.tenant_id = '${prefs.getString("tenant_id")}' AND COALESCE(n.is_deleted, 0) <> 1",
    };
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    await logApiRequest(
      url: uri,
      headers: headers,
      body: body,
      response: response,
      tag: 'NotifyList.getNotifications',
    );

    if (response.statusCode == 200) {
      setState(() {
        notifications = jsonDecode(response.body)['results'];
      });
    } else {}
  }
}
