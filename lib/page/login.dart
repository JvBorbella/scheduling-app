import 'dart:convert';
import 'package:all_validations_br/all_validations_br.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/button/switch_button.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/mask/cnpj.dart';
import 'package:scheduling/requests/company.dart';
import 'package:scheduling/requests/login_request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduling/style/color.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool rememberLogin = false, obscurePassword = true;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  String? _rememberUser;
  String? _rememberPassword;

  @override
  void initState() {
    super.initState();
    logoUrl();
    //getImage();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _rememberUser = prefs.getString('user');
        _rememberPassword = prefs.getString('pass');
        _userController.text = _rememberUser ?? '';
        _passwordController.text = _rememberPassword ?? '';
        rememberLogin = prefs.getBool('rememberLogin') ?? false;
        _cnpjController.text = CustomCnpjAlfanumericoFormatter()
            .formatEditUpdate(
              TextEditingValue(text: prefs.getString("cnpjCompany") ?? ''),
              TextEditingValue(text: prefs.getString("cnpjCompany") ?? ''),
            )
            .text;
      });
    });
  }

  String urlImage = '';

  void logoUrl() {
    CompanyRequest().getCompany().then((response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          urlImage = data['results'][0]['logo_url'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.primaryColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.primaryColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              size: 30,
              color: ColorsApp.secondaryColor,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ModalMod1(
                  title: 'Configurações do app',
                  content: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFieldMod1(
                          labelText: 'CNPJ da empresa',
                          controller: _cnpjController,
                          inputFormatters: [CnpjAlfaMask()],
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setString(
                      "cnpjCompany",
                      unMasked(_cnpjController.text)!,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 500),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                spacing: 20,
                children: [
                  urlImage != ''
                      ? Image.network(
                          urlImage,
                          //width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Symbols.hide_image,
                          size: 100,
                          color: ColorsApp.secondaryColor,
                        ),
                  TextFieldMod1(
                    labelText: 'Usuário',
                    controller: _userController,
                    onChanged: rememberLogin
                        ? (value) {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setString('user', value);
                            });
                          }
                        : null,
                  ),
                  TextFieldMod1(
                    labelText: 'Senha',
                    controller: _passwordController,
                    obscureText: obscurePassword,
                    onChanged: rememberLogin
                        ? (value) {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setString('pass', value);
                            });
                          }
                        : null,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: ColorsApp.secondaryColor,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: Row(
                          children: [
                            Text(
                              'Lembrar meu login',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorsApp.secondaryColor,
                              ),
                            ),
                            SwitchButton(
                              isChecked: rememberLogin,
                              onChanged: (value) {
                                setState(() {
                                  rememberLogin = value!;
                                });
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setBool('rememberLogin', value!);
                                  if (value) {
                                    prefs.setString(
                                      'user',
                                      _userController.text,
                                    );
                                    prefs.setString(
                                      'pass',
                                      _passwordController.text,
                                    );
                                  } else {
                                    prefs.remove('user');
                                    prefs.remove('pass');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: null,
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            color: ColorsApp.secondaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: ColorsApp.secondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ButtonMod1(
                    color: ColorsApp.secondaryColor,
                    text: 'Entrar',
                    onPressed: () =>
                        LoginRequest.login(
                              _userController.text,
                              _passwordController.text,
                            )
                            .then((_) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => App()),
                              );
                            })
                            .onError((error, stackTrace) {
                              if (_userController.text.isEmpty ||
                                  _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Preencha todos os campos"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }),
                  ),
                  Center(
                    child: Text(
                      'By Oblynx',
                      style: TextStyle(color: ColorsApp.secondaryColor),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Versão: 1.0.0',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
