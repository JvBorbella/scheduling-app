import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:scheduling/function/log_request_function.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyRequest {
  Future<http.Response> getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('refresh_token');
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    final uri = Uri.parse(baseUrl + Endpoints.list);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-TENANT-ID': prefs.getString('empresa_id') ?? '',
    };
    final body = {
      "q":
          "SELECT * FROM companies c WHERE c.tenant_id = '${prefs.getString('empresa_id')}'",
    };
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );
    await logApiRequest(
      url: uri,
      headers: headers,
      body: body,
      response: response,
      tag: 'CompanyRequest.getCompany',
    );
    return response;
  }
}
