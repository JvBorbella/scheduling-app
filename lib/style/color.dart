import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:scheduling/requests/company.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorsApp {
  static Color primaryColor = Colors.white;
  static Color secondaryColor = Colors.black;

  Future<void> getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final empresaId = prefs.getString("empresa_id");
    if (empresaId != null) {
      CompanyRequest().getCompany().then((response) async {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['results'].isEmpty) {
            prefs.setString('primary_color', '');
            prefs.setString('secondary_color', '');
            prefs.setString('logo_url', '');
          } else {
            await prefs.setString(
              'primary_color',
              data['results'][0]['primary_color'],
            );
            await prefs.setString(
              'secondary_color',
              data['results'][0]['secondary_color'],
            );
            await prefs.setString('logo_url', data['results'][0]['logo_url']);
          }
        }
      });
    }
  }

  static void setColors() async {
    final prefs = await SharedPreferences.getInstance();
    final _primaryColor = prefs.getString('primary_color') ?? '';
    final _secondaryColor = prefs.getString('secondary_color') ?? '';
    if (_primaryColor != '') {
      primaryColor = Color(int.parse(_primaryColor.replaceAll('#', '0xff')));
    }
    if (_secondaryColor != '') {
      secondaryColor = Color(
        int.parse(_secondaryColor.replaceAll('#', '0xff')),
      );
    }
  }
}
