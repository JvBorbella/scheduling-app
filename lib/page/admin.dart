import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:all_validations_br/all_validations_br.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/modal/modal_mod2.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/mask/cnpj.dart';
import 'package:scheduling/page/users.dart';
import 'package:scheduling/requests/company.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduling/style/color.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  File? _selectedImage;
  final TextEditingController _imageController = TextEditingController();
  late CircleColorPickerController _primaryController;
  late CircleColorPickerController _secondaryController;

  final TextEditingController _quickMessageTitleController =
      TextEditingController();
  final TextEditingController _quickMessageController = TextEditingController();

  String _primaryColor = '',
      _secondaryColor = '',
      _nomeUsuario = '',
      _usuarioId = '',
      _companyName = '';

  @override
  void dispose() {
    _cnpjController.dispose();
    _nameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
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

  Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');

    // Se não houver canal alpha, adiciona FF (100% opaco)
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    return Color(int.parse(hex, radix: 16));
  }

  Future<void> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeUsuario = prefs.getString('nome_usuario');
    final usuarioId = prefs.getString('usuario_id');
    final companyName = prefs.getString('company_name');
    if (nomeUsuario != null && usuarioId != null && companyName != null) {
      setState(() {
        _nomeUsuario = nomeUsuario;
        _usuarioId = usuarioId;
        _companyName = companyName;
      });
    }
  }

  Future<void> getCompany() async {
    CompanyRequest().getCompany().then((response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _cnpjController.text = data['results'][0]['cnpj'];
          _nameController.text = data['results'][0]['name'];
          _companyNameController.text = data['results'][0]['trade_name'];
          _phoneController.text = data['results'][0]['phone'];
          _emailController.text = data['results'][0]['email'];
          _primaryColor = data['results'][0]['primary_color'];
          _secondaryColor = data['results'][0]['secondary_color'];
          _primaryController.color = hexToColor(_primaryColor);
          _secondaryController.color = hexToColor(_secondaryColor);
          _imageController.text = data['results'][0]['logo_url'];
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getUsuario();
    getCompany();
    _primaryController = CircleColorPickerController(
      initialColor: ColorsApp.primaryColor,
    );

    _secondaryController = CircleColorPickerController(
      initialColor: ColorsApp.secondaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        backgroundColor: ColorsApp.primaryColor,
        appBar: AppBar(
          backgroundColor: ColorsApp.primaryColor,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: ColorsApp.secondaryColor,
            ),
          ),
          title: Text(
            'Administração do sistema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsApp.secondaryColor,
            ),
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: ColorsApp.secondaryColor),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: DrawerTab(
              nomeUsuario: _nomeUsuario,
              companyName: _companyName,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Empresa (Expanded by default)
                      AdminTile(
                        title: 'Empresa',
                        initialExpanded: false,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            TextFieldMod1(
                              controller: _cnpjController,
                              labelText: 'CNPJ',
                              inputFormatters: [CnpjAlfaMask()],
                            ),
                            TextFieldMod1(
                              controller: _nameController,
                              labelText: 'Nome',
                            ),
                            TextFieldMod1(
                              controller: _companyNameController,
                              labelText: 'Razão Social',
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFieldMod1(
                                    controller: _phoneController,
                                    labelText: 'Telefone',
                                    inputFormatters: [PhoneMask()],
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFieldMod1(
                                    controller: _emailController,
                                    labelText: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                            TextFieldMod1(
                              controller: _cepController,
                              labelText: 'CEP',
                              keyboardType: TextInputType.number,
                              suffixIcon: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.search),
                              ),
                              inputFormatters: [CepMask()],
                            ),

                            TextFieldMod1(
                              controller: _addressController,
                              labelText: 'Endereço',
                            ),
                            TextFieldMod1(
                              controller: _complementoController,
                              labelText: 'Complemento',
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFieldMod1(
                                    controller: _bairroController,
                                    labelText: 'Bairro',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFieldMod1(
                                    controller: _numeroController,
                                    labelText: 'Número',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFieldMod1(
                                    controller: _cidadeController,
                                    labelText: 'Cidade',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFieldMod1(
                                    controller: _estadoController,
                                    labelText: 'Estado',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            // 2x2 Action Grid
                            Row(
                              children: [
                                Expanded(
                                  child: AdminGridItem(
                                    icon: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : _imageController.text != ''
                                        ? Image.network(
                                            _imageController.text,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Symbols.hide_image,
                                            size: 44,
                                            color: ColorsApp.secondaryColor,
                                          ),
                                    label: _selectedImage != null
                                        ? _selectedImage!.path
                                        : 'Logo da empresa',
                                    onTap: () {
                                      _pickImage();
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      AdminGridItem(
                                        icon: CustomPaint(
                                          size: const Size(40, 40),
                                          painter: ColorWheelPainter(),
                                        ),
                                        label: '',
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => ModalMod2(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                spacing: 10,
                                                children: [
                                                  ButtonMod1(
                                                    text: 'Cor primária',
                                                    width: double.infinity,
                                                    color: ColorsApp
                                                        .secondaryColor,
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return StatefulBuilder(
                                                          builder:
                                                              (
                                                                context,
                                                                setModalState,
                                                              ) {
                                                                return ModalMod2(
                                                                  content: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      CircleColorPicker(
                                                                        controller:
                                                                            _primaryController,
                                                                        onChanged: (color) {
                                                                          setModalState(
                                                                            () {
                                                                              _primaryColor = '#${color.value.toRadixString(16).substring(2)}';
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                      ButtonMod1(
                                                                        color: Colors
                                                                            .black,
                                                                        onPressed: () =>
                                                                            Navigator.pop(
                                                                              context,
                                                                            ),
                                                                        text:
                                                                            'Salvar',
                                                                        width: double
                                                                            .infinity,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  ButtonMod1(
                                                    text: 'Cor secundária',
                                                    width: double.infinity,
                                                    color: ColorsApp
                                                        .secondaryColor,
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return StatefulBuilder(
                                                          builder:
                                                              (
                                                                context,
                                                                setModalState,
                                                              ) {
                                                                return ModalMod2(
                                                                  content: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    spacing: 10,
                                                                    children: [
                                                                      CircleColorPicker(
                                                                        controller:
                                                                            _secondaryController,
                                                                        onChanged: (color) {
                                                                          setModalState(
                                                                            () {
                                                                              _secondaryColor = '#${color.value.toRadixString(16).substring(2)}';
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                      ButtonMod1(
                                                                        color: Colors
                                                                            .black,
                                                                        onPressed: () =>
                                                                            Navigator.pop(
                                                                              context,
                                                                            ),
                                                                        text:
                                                                            'Salvar',
                                                                        width: double
                                                                            .infinity,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Primária ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ColorsApp.secondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              color: _primaryColor == ''
                                                  ? Colors.transparent
                                                  : hexToColor(_primaryColor),
                                            ),
                                          ),
                                          Text(
                                            " ${_primaryColor.toString()}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ColorsApp.secondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Secundária ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ColorsApp.secondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              color: _secondaryColor == ''
                                                  ? Colors.transparent
                                                  : hexToColor(_secondaryColor),
                                            ),
                                          ),
                                          Text(
                                            " ${_secondaryColor.toString()}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ColorsApp.secondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AdminGridItem(
                                    icon: Icon(
                                      Symbols.person_add,
                                      size: 44,
                                      color: ColorsApp.secondaryColor,
                                    ),
                                    label: 'Usuários',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserList(),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: AdminGridItem(
                                    icon: Icon(
                                      Symbols.group_add,
                                      size: 44,
                                      color: ColorsApp.secondaryColor,
                                    ),
                                    label: 'Perfis de usuário',
                                    onTap: () {
                                      // Action for user profiles
                                    },
                                  ),
                                ),
                              ],
                            ),
                            ButtonMod1(
                              text: 'Salvar',
                              width: double.infinity,
                              color: ColorsApp.secondaryColor,
                              onPressed: () async {
                                await dotenv.load(fileName: ".env");
                                final baseUrl = dotenv.env['BASE_URL']!;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final token = prefs.getString('access_token');
                                String urlImage = '';
                                try {
                                  var request = http.MultipartRequest(
                                    'POST',
                                    Uri.parse(
                                      'http://oblynx.com.br:8000${Endpoints.uploadImage}',
                                    ),
                                  );
                                  request.headers.addAll({
                                    'Authorization': 'Bearer $token',
                                  });
                                  if (_selectedImage != null) {
                                    String ext = _selectedImage!.path
                                        .split('.')
                                        .last
                                        .toLowerCase();
                                    MediaType mediaType = MediaType(
                                      'image',
                                      ext == 'png' ? 'png' : 'jpeg',
                                    );
                                    request.files.add(
                                      http.MultipartFile.fromBytes(
                                        'file',
                                        await _selectedImage!.readAsBytes(),
                                        filename: _selectedImage!.path
                                            .split('/')
                                            .last,
                                        contentType: mediaType,
                                      ),
                                    );
                                  }
                                  request.fields['folder'] = 'empresa';
                                  request.fields['usuario_id'] = _usuarioId;
                                  final clientKey = prefs.getString(
                                    "client_key",
                                  );
                                  if (clientKey != null) {
                                    request.fields['client_key'] = clientKey;
                                  }
                                  request.fields['flagpublico'] = '1';
                                  var streamedResponse = await request.send();
                                  var response = await http.Response.fromStream(
                                    streamedResponse,
                                  );
                                  if (response.statusCode == 200) {
                                    final dynamic decoded = json.decode(
                                      response.body,
                                    );
                                    urlImage = decoded['url'];
                                  } else {
                                    log('log envio imagem: ${response.body}');
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                      baseUrl + Endpoints.insertCompany,
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                      'X-TENANT-ID':
                                          "${prefs.getString("tenant_id")}",
                                    },
                                    body: json.encode({
                                      "name": _nameController.text,
                                      "trade_name": _companyNameController.text,
                                      "tenant_id":
                                          "${prefs.getString("empresa_id")}",
                                      "company_id":
                                          "${prefs.getString("company_id")}",
                                      "cnpj": unMasked(_cnpjController.text),
                                      "email": _emailController.text,
                                      "phone": unMasked(_phoneController.text),
                                      "zip_code": unMasked(_cepController.text),
                                      "street": _addressController.text,
                                      "street_number": _numeroController.text,
                                      "complement": _complementoController.text,
                                      "neighborhood": _bairroController.text,
                                      "city": _cidadeController.text,
                                      "state": _estadoController.text,
                                      "primary_color": _primaryColor,
                                      "secondary_color": _secondaryColor,
                                      "logo_url": urlImage,
                                      "is_headquarters": 0,
                                      "parent_id": null,
                                    }),
                                  );
                                  if (response.statusCode == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Filial cadastrada com sucesso!",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    prefs.setString(
                                      "cnpjCompany",
                                      unMasked(_cnpjController.text)!,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response.body),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Respostas rápidas
                      AdminTile(
                        title: 'Respostas rápidas',
                        initialExpanded: false,
                        content: Column(
                          spacing: 10,
                          children: [
                            TextFieldMod1(
                              controller: _quickMessageTitleController,
                              labelText: 'Título',
                            ),
                            TextFieldMod1(
                              controller: _quickMessageController,
                              labelText: 'Mensagem',
                              maxLines: 5,
                            ),
                            ButtonMod1(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final baseUrl = dotenv.env['BASE_URL'];
                                final response = await http.post(
                                  Uri.parse('$baseUrl${Endpoints.insert}'),
                                  headers: {
                                    'Authorization':
                                        'Bearer ${prefs.getString('access_token')}',
                                    'Content-Type': 'application/json',
                                    'X-TENANT-ID':
                                        "${prefs.getString("tenant_id")}",
                                  },
                                  body: jsonEncode({
                                    'tabela': "quick_responses",
                                    "values": {
                                      "title":
                                          _quickMessageTitleController.text,
                                      "content": _quickMessageController.text,
                                    },
                                  }),
                                );
                                if (response.statusCode == 201) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Resposta rápida salva!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.body),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              text: 'Salvar',
                              color: ColorsApp.secondaryColor,
                            ),
                          ],
                        ),
                      ),
                      // Pagamentos
                      const AdminTile(
                        title: 'Pagamentos',
                        initialExpanded: false,
                        content: Column(
                          children: [
                            SizedBox(height: 8),
                            Text(
                              'Opções de pagamento',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // Licenciamento
                      const AdminTile(
                        title: 'Licenciamento',
                        initialExpanded: false,
                        content: Column(
                          children: [
                            SizedBox(height: 8),
                            Text(
                              'Informações de licenciamento do sistema',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Action Buttons
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 16.0,
              //     vertical: 12.0,
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       OutlinedButton(
              //         onPressed: () => Navigator.pop(context),
              //         style: OutlinedButton.styleFrom(
              //           foregroundColor: ColorsApp.secondaryColor,
              //           side: const BorderSide(color: ColorsApp.secondaryColor, width: 1.5),
              //           padding: const EdgeInsets.symmetric(
              //             horizontal: 36,
              //             vertical: 12,
              //           ),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(12),
              //           ),
              //         ),
              //         child: const Text(
              //           'Descartar',
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ),
              //       ElevatedButton(
              //         onPressed: () {
              //           // Confirm/save and return
              //           Navigator.pop(context);
              //         },
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: ColorsApp.secondaryColor,
              //           foregroundColor: ColorsApp.primaryColor,
              //           padding: const EdgeInsets.symmetric(
              //             horizontal: 44,
              //             vertical: 12,
              //           ),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(12),
              //           ),
              //         ),
              //         child: const Text(
              //           'Aplicar',
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminTile extends StatefulWidget {
  final String title;
  final Widget? content;
  final bool initialExpanded;

  const AdminTile({
    super.key,
    required this.title,
    this.content,
    this.initialExpanded = false,
  });

  @override
  State<AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends State<AdminTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorsApp.primaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: ColorsApp.secondaryColor,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && widget.content != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: widget.content!,
            ),
        ],
      ),
    );
  }
}

class AdminGridItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const AdminGridItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: ColorsApp.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    final double angleStep = 2 * 3.141592653589793 / colors.length;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(rect, i * angleStep, angleStep, true, paint);
    }

    final innerPaint = Paint()
      ..color = ColorsApp.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
