import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:scheduling/requests/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyRequest {
  Future<http.Response> getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('refresh_token');
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    final response = await http.post(
      Uri.parse(baseUrl + Endpoints.list),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-TENANT-ID': prefs.getString('empresa_id') ?? '',
      },
      body: json.encode({
        "q":
            "SELECT * FROM companies c WHERE c.tenant_id = '${prefs.getString('empresa_id')}'",
      }),
    );
    return response;
  }
}
