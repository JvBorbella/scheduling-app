import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:scheduling/requests/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginRequest {
  static Future<void> login(String user, String password) async {
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    final response = await http.post(
      Uri.parse(baseUrl + Endpoints.login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user": user, "pass": password, "api": "app"}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print(data);
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString("access_token", data["access_token"]);
        prefs.setString("refresh_token", data["refresh_token"]);
        prefs.setString("empresa_id", data["empresa_id"]);
        prefs.setString("usuario_id", data["usuario_id"]);
        prefs.setString("nome_usuario", data["nome"]);
      });
      var responseData = await http.post(
        Uri.parse(baseUrl + Endpoints.list),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${data["access_token"]}",
          "X-Tenant-ID": "${data["empresa_id"]}",
        },
        body: jsonEncode({
          "q":
              "SELECT t.id, l.client_key, c.id as company_id, c.name AS company_name FROM tenants t INNER JOIN licenses l ON t.id = l.tenant_id INNER JOIN companies c ON t.id = c.tenant_id WHERE t.id = '${data["empresa_id"]}'",
        }),
      );
      final Map<String, dynamic> dataResponse = json.decode(responseData.body);
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString("client_key", dataResponse['results'][0]["client_key"]);
        prefs.setString("tenant_id", dataResponse['results'][0]["id"]);
        prefs.setString("company_id", dataResponse['results'][0]["company_id"]);
        prefs.setString(
          "company_name",
          dataResponse['results'][0]["company_name"],
        );
      });
    } else {
      throw Exception(json.decode(response.body));
    }
  }
}
