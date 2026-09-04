import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:scheduling/function/token_expiry_manager.dart';
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
      log(data['avatar_url']);
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString("access_token", data["access_token"]);
        prefs.setString("refresh_token", data["refresh_token"]);
        prefs.setString("empresa_id", data["empresa_id"]);
        prefs.setString("usuario_id", data["usuario_id"]);
        prefs.setString("nome_usuario", data["nome"]);
        prefs.setString("avatar_url", data['avatar_url']);
        prefs.setString(
          "client_key",
          data["servicos_contratados"][0]["license"]["client_key"],
        );
        prefs.setString(
          "expires_at",
          data["servicos_contratados"][0]["license"]["expires_at"],
        );
        prefs.setString(
          "plan",
          data["servicos_contratados"][0]["license"]["plan"],
        );
        prefs.setInt(
          "is_active",
          data["servicos_contratados"][0]["license"]["is_active"],
        );
        //prefs.setInt("is_admin", data["is_admin"]);
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
            "SELECT c.tenant_id, c.companies_id as company_id, c.name AS company_name, p.cpf_cnpj AS cnpj FROM companies c INNER JOIN persons p ON p.persons_id = c.person_id WHERE c.tenant_id = '${data["empresa_id"]}'",
        }),
      );
      final Map<String, dynamic> dataResponse = json.decode(responseData.body);
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString(
          "tenant_id",
          dataResponse['results'][0]["tenant_id"] ?? '',
        );
        prefs.setString(
          "company_id",
          dataResponse['results'][0]["company_id"] ?? '',
        );
        prefs.setString(
          "company_name",
          dataResponse['results'][0]["company_name"] ?? '',
        );
        prefs.setString(
          "cnpjCompany",
          dataResponse['results'][0]["cnpj"] ?? '',
        );
      });
      TokenExpiryManager.startExpiryTimer(
        data["expires_in"],
        data["refresh_expires_in"],
      );
    } else {
      throw Exception(json.decode(response.body));
    }
  }
}
