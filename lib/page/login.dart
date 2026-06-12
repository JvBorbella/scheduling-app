import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _imageController = TextEditingController();
  File? _selectedImage;

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
              color: Colors.black,
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
                          controller: _imageController,
                          labelText: 'Selecione uma imagem',
                          suffixIcon: IconButton(
                            onPressed: _pickImage,
                            icon: const Icon(Symbols.more_horiz),
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
                _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Icon(Symbols.hide_image, size: 100),
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
                        style: TextStyle(color: Colors.black, decoration: TextDecoration.underline, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                ButtonMod1(
                  color: Colors.black,
                  text: 'Entrar',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => App()),
                  ),
                ),
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageController.text = image.name;
        });
        print('Imagem selecionada: ${image.path}');
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }
}
