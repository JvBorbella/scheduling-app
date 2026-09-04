import 'dart:convert';
import 'package:all_validations_br/all_validations_br.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/button/switch_button.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/return/messenge.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/function/log_request_function.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/mask/cnpj.dart';
import 'package:scheduling/requests/company.dart';
import 'package:scheduling/requests/login_request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduling/style/color.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool rememberLogin = false, obscurePassword = true, obscureNewPassword = true;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  String? _rememberUser;
  String? _rememberPassword;
  String version = '';

  @override
  void initState() {
    super.initState();
    logoUrl();
    _getAppVersion();
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

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  void logoUrl() {
    CompanyRequest().getCompany().then((response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          urlImage = data['results'][0]['logo_url'] ?? '';
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
                        onPressed: () {
                          var sendEmail = false;
                          TextEditingController codeController =
                              TextEditingController();
                          TextEditingController newPasswordController =
                              TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setState) => ModalMod1(
                                title: sendEmail
                                    ? 'Redefinir senha'
                                    : 'Esqueci minha senha',
                                content: sendEmail
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 10,
                                        children: [
                                          TextFieldMod1(
                                            labelText:
                                                'Código recebido na caixa de email',
                                            controller: codeController,
                                          ),
                                          TextFieldMod1(
                                            labelText: 'Nova senha',
                                            controller: newPasswordController,
                                            obscureText: obscureNewPassword,
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.visibility),
                                              onPressed: () {
                                                setState(() {
                                                  obscureNewPassword =
                                                      !obscureNewPassword;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFieldMod1(
                                            labelText: 'Email',
                                            controller: _userController,
                                          ),
                                        ],
                                      ),
                                textButton: sendEmail
                                    ? 'Redefinir senha'
                                    : 'Enviar email',
                                onPressed: () async {
                                  final baseUrl = dotenv.env['BASE_URL'];
                                  if (sendEmail) {
                                    final resetUri = Uri.parse(
                                      '$baseUrl/api/auth/reset_password_code',
                                    );
                                    final resetBody = {
                                      'email': _userController.text,
                                      'code': codeController.text,
                                      'password': newPasswordController.text,
                                    };
                                    final response = await http.post(
                                      resetUri,
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode(resetBody),
                                    );
                                    await logApiRequest(
                                      url: resetUri,
                                      headers: {'Content-Type': 'application/json'},
                                      body: {
                                        'email': _userController.text,
                                        'code': codeController.text,
                                        'password': '******',
                                      },
                                      response: response,
                                      tag: 'Login - reset_password_code',
                                    );
                                    if (response.statusCode == 200) {
                                      sendEmail = false;
                                      Navigator.of(context).pop();
                                      Message.showReturnOverlay(
                                        context,
                                        Colors.green,
                                        Icons.check,
                                        'Senha redefinida com sucesso!',
                                      );
                                    } else {
                                      Message.showReturnOverlay(
                                        context,
                                        Colors.red,
                                        Icons.error,
                                        response.body.toString(),
                                      );
                                    }
                                  } else {
                                    final forgotUri = Uri.parse(
                                      '$baseUrl/api/auth/forgot_password_code',
                                    );
                                    final forgotBody = {
                                      'email': _userController.text,
                                    };
                                    final response = await http.post(
                                      forgotUri,
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode(forgotBody),
                                    );
                                    await logApiRequest(
                                      url: forgotUri,
                                      headers: {'Content-Type': 'application/json'},
                                      body: forgotBody,
                                      response: response,
                                      tag: 'Login - forgot_password_code',
                                    );
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        sendEmail = true;
                                      });
                                    } else {
                                      Message.showReturnOverlay(
                                        context,
                                        Colors.red,
                                        Icons.error,
                                        response.body,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
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
                                Message.showReturnOverlay(
                                  context,
                                  Colors.red,
                                  Icons.error,
                                  "Preencha todos os campos",
                                );
                              } else {
                                Message.showReturnOverlay(
                                  context,
                                  Colors.red,
                                  Icons.error,
                                  error.toString(),
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
                      'Versão: $version',
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
