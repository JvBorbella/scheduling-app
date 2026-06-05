import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/button/switch_button.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool rememberLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              size: 30,
              color: Color(0xFF1E88E5),
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
                        TextFieldMod1(labelText: 'CNPJ da empresa'),
                        SizedBox(height: 10),
                        TextFieldMod1(
                          labelText: 'Selecione uam imagem',
                          suffixIcon: IconButton(
                            onPressed: null,
                            icon: Icon(Symbols.more_horiz),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Symbols.hide_image, size: 100),
                TextFieldMod1(labelText: 'Usuário'),
                TextFieldMod1(labelText: 'Senha', obscureText: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      child: Row(
                        children: [
                          Text(
                            'Lembrar meu login',
                            style: TextStyle(fontSize: 12),
                          ),
                          SwitchButton(
                            isChecked: rememberLogin,
                            onChanged: (value) =>
                                setState(() => rememberLogin = value),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: null,
                      child: Text(
                        'Esqueci minha senha',
                        style: TextStyle(color: Colors.blue[300], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                ButtonMod1(text: 'Entrar', onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => App()),
                ),),
                Center(child: Text('By Oblynx')),
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
    );
  }
}
