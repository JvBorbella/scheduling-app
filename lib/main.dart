import 'dart:convert';
import 'dart:developer';

import 'package:all_validations_br/all_validations_br.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/button/text_icon_button.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/modal/modal_mod2.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/mask/cnpj.dart';
import 'package:scheduling/modals_crud/crud_customer.dart';
import 'package:scheduling/modals_crud/crud_scheduling.dart';
import 'package:scheduling/modals_crud/crud_services.dart';
import 'package:scheduling/page/admin.dart';
import 'package:scheduling/page/users.dart';
import 'package:scheduling/requests/company.dart';
import 'package:scheduling/requests/customers.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:scheduling/requests/payment.dart';
import 'package:scheduling/page/client.dart';
import 'package:scheduling/page/login.dart';
import 'package:scheduling/page/messenge.dart';
import 'package:scheduling/page/notify.dart';
import 'package:scheduling/page/shedulings.dart';
import 'package:scheduling/style/color.dart';
import 'package:searchfield/searchfield.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await ColorsApp.getCompany();
  await ColorsApp.setColors();
  runApp(const MyApp());
}

class Services {
  final String id;
  final String name;
  final String code;
  final double price;

  Services({this.id = '', this.name = '', this.code = '', this.price = 0.0});

  factory Services.fromJson(Map<String, dynamic> json) {
    return Services(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Clients {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String cpf;
  final String cnpj;

  Clients({
    this.id = '',
    this.name = '',
    this.phone = '',
    this.email = '',
    this.cpf = '',
    this.cnpj = '',
  });

  factory Clients.fromJson(Map<String, dynamic> json) {
    return Clients(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      cnpj: json['cnpj']?.toString() ?? '',
    );
  }
}

class App extends StatefulWidget {
  final dynamic child;
  final String title;
  final int selectedIndex;
  const App({super.key, this.child, this.title = '', this.selectedIndex = 0});

  static void showAddModal(
    BuildContext context, {
    Map<String, dynamic>? initialData,
  }) {
    context.findAncestorStateOfType<_AppState>()?.showAddModal(
      initialData: initialData,
    );
  }

  @override
  State<App> createState() => _AppState();
}

final List<Widget> _pages = <Widget>[
  Shedulings(),
  ClientList(),
  SizedBox(),
  MessengeList(),
  NotifyList(),
  UserList(),
];

int _selectedIndex = 0;

class _AppState extends State<App> {
  List<SearchFieldListItem<Services>> services = [];
  SearchFieldListItem<Services>? selectedValue;
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String _nomeUsuario = '';
  String _companyName = '';

  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _listServices() async {
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token") ?? "";

    try {
      final response = await http.post(
        Uri.parse(baseUrl + Endpoints.list),
        headers: {
          "Authorization": "Bearer $token",
          "X-Tenant-ID": "${prefs.getString("tenant_id")}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "q":
              "SELECT * FROM products p WHERE p.tenant_id = '${prefs.getString("tenant_id")}'",
        }),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        List dynamicList = [];
        if (decoded is List) {
          dynamicList = decoded;
        } else if (decoded is Map) {
          if (decoded['data'] is List)
            dynamicList = decoded['data'];
          else if (decoded['result'] is List)
            dynamicList = decoded['result'];
          else if (decoded['rows'] is List)
            dynamicList = decoded['rows'];
          else if (decoded['records'] is List)
            dynamicList = decoded['records'];
          else {
            // Se as chaves comuns não funcionarem, tenta pegar a primeira lista que encontrar no Map
            for (var value in decoded.values) {
              if (value is List) {
                dynamicList = value;
                break;
              }
            }
          }
        }

        if (dynamicList.isNotEmpty) {
          setState(() {
            services = dynamicList.map<SearchFieldListItem<Services>>((e) {
              final service = Services.fromJson(e);
              final displayNome = service.name.isNotEmpty
                  ? service.name
                  : (service.code.isNotEmpty ? service.code : 'Item Sem Nome');
              return SearchFieldListItem<Services>(
                displayNome,
                value: service.name,
                item: service,
                child: searchChild(service),
              );
            }).toList();
          });
          print('ITENS CARREGADOS NA LISTA: ${services.length}');
        } else {
          print('NENHUMA LISTA FOI ENCONTRADA NA RESPOSTA DA API.');
        }
      } else {
        print(
          'Erro ao buscar serviços: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Erro de requisição: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _listServices();
    getNomeUsuario();
  }

  Widget searchChild(Services service, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        service.name.isNotEmpty ? service.name : 'Serviço sem nome',
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.blue : ColorsApp.secondaryColor,
        ),
      ),
    );
  }

  Future<void> getNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeUsuario = prefs.getString('nome_usuario');
    final companyName = prefs.getString('company_name');
    if (nomeUsuario != null && companyName != null) {
      setState(() {
        _nomeUsuario = nomeUsuario;
        _companyName = companyName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        backgroundColor: ColorsApp.primaryColor,
        appBar: AppBar(
          backgroundColor: ColorsApp.primaryColor,
          iconTheme: IconThemeData(color: ColorsApp.secondaryColor, size: 30),
          leading: IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => ModalMod1(
                title: 'Sair do aplicativo?',
                textButton: 'Sair',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                ),
              ),
            ),
            icon: Icon(Icons.logout_outlined),
          ),
          title: Text(
            _getAppBarTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsApp.secondaryColor,
            ),
          ),
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: DrawerTab(
              nomeUsuario: _nomeUsuario,
              companyName: _companyName,
            ),
          ),
        ),
        body:
            widget.child ??
            IndexedStack(index: _selectedIndex, children: _pages),
        floatingActionButton: FloatingActionButton(
          backgroundColor: ColorsApp.secondaryColor,
          shape: const CircleBorder(),
          onPressed: () async {
            final modal = await CrudScheduling.modalMod1(
              context,
              '',
              '',
              '',
              '',
              '',
            );
            if (_selectedIndex == 0) {
              showDialog(context: context, builder: (context) => modal);
            } else {
              showAddModal();
            }
          },
          child: Icon(Icons.add, color: ColorsApp.primaryColor, size: 30),
        ),
        // Posiciona o FAB perfeitamente no centro cortando/sobrepondo a barra
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey, width: 2),
              // right: BorderSide(color: Colors.grey, width: 2),
              // left: BorderSide(color: Colors.grey, width: 2),
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomAppBar(
              padding: EdgeInsets.zero,
              height: 60, // Ajuste a altura conforme seu design
              color: ColorsApp.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Symbols.event,
                      color: _selectedIndex == 0
                          ? ColorsApp.secondaryColor
                          : Colors.grey,
                      size: _selectedIndex == 0 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 0),
                  ),
                  IconButton(
                    icon: Icon(
                      Symbols.account_box,
                      color: _selectedIndex == 1
                          ? ColorsApp.secondaryColor
                          : Colors.grey,
                      size: _selectedIndex == 1 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 1),
                  ),

                  // Em vez de um item de menu, apenas um espaço vazio onde o FAB vai flutuar por cima
                  const SizedBox(width: 40),

                  IconButton(
                    icon: ImageIcon(
                      AssetImage('assets/icons/WhatsApp.png'),
                      color: _selectedIndex == 3
                          ? ColorsApp.secondaryColor
                          : Colors.grey,
                      size: _selectedIndex == 3 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 3),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: _selectedIndex == 4
                          ? ColorsApp.secondaryColor
                          : Colors.grey,
                      size: _selectedIndex == 4 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAddModal({Map<String, dynamic>? initialData}) {
    // Limpa a seleção anterior ao abrir o modal para um novo agendamento
    selectedValue = null;
    _serviceController.clear();

    String selectedPaymentType = 'pix';
    final TextEditingController _cardNumberController = TextEditingController();
    final TextEditingController _cardholderController = TextEditingController();
    final TextEditingController _expiryMonthController =
        TextEditingController();
    final TextEditingController _expiryYearController = TextEditingController();
    final TextEditingController _cvvController = TextEditingController();
    final TextEditingController _cpfController = TextEditingController();
    final TextEditingController _amountController = TextEditingController(
      text: initialData?['total_amount']?.toString() ?? '0.10',
    );
    final TextEditingController _clientController = TextEditingController(
      text: initialData?['client']?.toString() ?? '',
    );
    final TextEditingController _dateTimeController = TextEditingController(
      text: initialData?['scheduled_date']?.toString() ?? '',
    );
    // Se tiver nome do serviço em initialData, tenta preencher
    if (initialData?['service_name'] != null) {
      _serviceController.text = initialData!['service_name'].toString();
      // Opcionalmente você poderia buscar na lista `services` se o item existe para atribuir ao `selectedValue`
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _selectedIndex == 3
            ? ModalMod2(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ButtonMod1(
                      color: ColorsApp.secondaryColor,
                      text: 'Cliente',
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                        Navigator.pop(context);
                        showAddModal();
                      },
                    ),
                    SizedBox(height: 10),
                    ButtonMod1(
                      color: ColorsApp.secondaryColor,
                      text: 'Agendamento',
                      onPressed: () {
                        setState(() => _selectedIndex = 0);
                        Navigator.pop(context);
                        showAddModal();
                      },
                    ),
                  ],
                ),
              )
            : _selectedIndex == 1
            ? CrudCustomer.modalMod1(
                context,
                '',
                nameController,
                cpfController,
                emailController,
                phoneController,
              )
            : ModalMod1(
                title: _selectedIndex == 0 ? 'Confirmar Agendamento' : null,
                textButton: _selectedIndex == 0 ? 'Confirmar e Pagar' : null,
                onPressed: null,
                content: _selectedIndex == 4
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TextFieldMod1(
                            labelText: 'Selecione Data e Horário',
                            readOnly: true,
                            suffixIcon: Icon(Icons.calendar_month),
                          ),
                          const SizedBox(height: 10),
                          TextFieldMod1(labelText: 'Descrição', maxLines: 5),
                        ],
                      )
                    : null,
              ),
      ),
    );
  }

  // Simplifica a lógica de definição do título
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Agendamentos';
      case 1:
        return 'Clientes';
      case 3:
        return 'Chat';
      case 4:
        return 'Notificações';
      case 5:
        return 'Usuários';
      default:
        return widget.title;
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agendamentos',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const Login(),
    );
  }
}

class DrawerTab extends StatefulWidget {
  final String nomeUsuario;
  final String companyName;
  const DrawerTab({
    super.key,
    required this.nomeUsuario,
    required this.companyName,
  });

  @override
  State<DrawerTab> createState() => _DrawerTabState();
}

class _DrawerTabState extends State<DrawerTab> {
  List<dynamic> services = [];
  final TextEditingController _nameServiceController = TextEditingController();
  final TextEditingController _descripTionServiceController =
      TextEditingController();
  final TextEditingController _priceServiceController = TextEditingController();

  @override
  void dispose() {
    _nameServiceController.dispose();
    _descripTionServiceController.dispose();
    _priceServiceController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await dotenv.load(fileName: ".env");
    final baseUrl = dotenv.env['BASE_URL']!;

    final response = await http.post(
      Uri.parse(baseUrl + Endpoints.list),
      headers: {
        'Authorization': 'Bearer ${prefs.getString('access_token')}',
        'Content-Type': 'application/json',
        'X-TENANT-ID': '${prefs.getString('empresa_id')}',
      },
      body: jsonEncode({
        "q":
            "SELECT * FROM products WHERE tenant_id = '${prefs.getString('tenant_id')}' AND COALESCE(is_deleted,0) <> 1",
      }),
    );

    return jsonDecode(response.body);
  }

  //late Future<Map<String, dynamic>> _futureProducts;

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorsApp.secondaryColor,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: ColorsApp.primaryColor,
          size: 20,
        ),
      ),
      backgroundColor: ColorsApp.primaryColor,
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: ColorsApp.secondaryColor,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    maxRadius: 25,
                    backgroundColor: ColorsApp.primaryColor,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: ColorsApp.secondaryColor,
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: ColorsApp.primaryColor,
                            fontSize: 12,
                          ), // Estilo padrão/base
                          children: [
                            TextSpan(
                              text: 'Usuário: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ), // Aplica negrito apenas aqui
                            ),
                            TextSpan(text: widget.nomeUsuario),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: ColorsApp.primaryColor,
                            fontSize: 12,
                          ), // Estilo padrão/base
                          children: [
                            TextSpan(
                              text: 'Empresa: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ), // Aplica negrito apenas aqui
                            ),
                            TextSpan(
                              text: widget
                                  .companyName, // Herda o estilo padrão (cor branca, sem negrito)
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: ColorsApp.primaryColor,
                            fontSize: 12,
                          ), // Estilo padrão/base
                          children: [
                            TextSpan(
                              text: 'Perfil: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ), // Aplica negrito apenas aqui
                            ),
                            TextSpan(
                              text:
                                  'Sem perfil', // Herda o estilo padrão (cor branca, sem negrito)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              onTap: () {
                Navigator.pop(context); // Fechar o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              },
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: ColorsApp.secondaryColor,
              ),
              title: Text(
                'Área do admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorsApp.secondaryColor,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: ColorsApp.secondaryColor, width: 1),
              ),
            ),
            SizedBox(height: 10),
            ExpandedTile(
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: ColorsApp.secondaryColor,
              ),
              theme: ExpandedTileThemeData(
                trailingPadding: EdgeInsets.all(5),
                headerColor: Colors.transparent, // Cabeçalho branco
                contentBackgroundColor:
                    ColorsApp.primaryColor, // Fundo do conteúdo cinza claro
                // Remove o preenchimento padrão para os Dividers encostarem nas bordas laterais
                contentPadding: EdgeInsets.zero,
                headerPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                // 1. Quando FECHADO: Totalmente arredondado
                headerBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsApp.secondaryColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),

                // 2. Quando ABERTO: Arredondado apenas em cima, reto embaixo
                fullExpandedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsApp.secondaryColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                ),

                // Remove a borda interna nativa para não duplicar com a de cima
                contentBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              controller: ExpandedTileController(),
              title: Text(
                "Relatórios",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorsApp.secondaryColor,
                  fontSize: 16,
                ),
              ),
              content: Column(mainAxisSize: MainAxisSize.min, children: []),
            ),
            SizedBox(height: 10),
            ExpandedTile(
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: ColorsApp.secondaryColor,
              ),
              theme: ExpandedTileThemeData(
                trailingPadding: EdgeInsets.all(5),
                headerColor: Colors.transparent, // Cabeçalho branco,
                contentBackgroundColor:
                    ColorsApp.primaryColor, // Fundo do conteúdo cinza claro
                // Remove o preenchimento padrão para os Dividers encostarem nas bordas laterais
                contentPadding: EdgeInsets.zero,
                headerPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                // 1. Quando FECHADO: Totalmente arredondado
                headerBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsApp.secondaryColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),

                // 2. Quando ABERTO: Arredondado apenas em cima, reto embaixo
                fullExpandedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsApp.secondaryColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                ),

                // Remove a borda interna nativa para não duplicar com a de cima
                contentBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              controller: ExpandedTileController(),
              title: Text(
                "Serviços",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorsApp.secondaryColor,
                  fontSize: 16,
                ),
              ),

              // Conteúdo com múltiplos Containers/Itens separados por linhas
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Linha divisória entre o título e o primeiro item
                  const Divider(color: Colors.grey, height: 1, thickness: 1),

                  // Primeiro Item (Cadastro)
                  ListTile(
                    title: Text(
                      "Cadastrar Novo",
                      style: TextStyle(
                        color: ColorsApp.secondaryColor,
                        fontSize: 15,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () {
                      CrudServices.modal1(context, '', '', '', 0);
                    },
                  ),

                  // Linha divisória entre os itens internos
                  const Divider(color: Colors.grey, height: 1, thickness: 1),

                  // Segundo Item (Consulta de preço)
                  ListTile(
                    title: Text(
                      "Cadastrados",
                      style: TextStyle(
                        color: ColorsApp.secondaryColor,
                        fontSize: 15,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () async {
                      var productData = await getProducts();

                      showDialog(
                        context: context,
                        builder: (BuildContext context) => StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return ModalMod2(
                              title: "Produtos cadastrados",
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Column(
                                  spacing: 10,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: productData['results'].length,
                                      itemBuilder: (BuildContext context, int index) {
                                        var product =
                                            productData['results'][index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: CardList(
                                            title: product['name'],
                                            text:
                                                'Descrição: ${product['description']}\nPreço: ${product['price']}',
                                            iconButton: IconButton(
                                              onPressed: () =>
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        CrudServices.modal1(
                                                          context,
                                                          product['id'],
                                                          product['name'],
                                                          product['description'],
                                                          double.parse(
                                                            product['price'],
                                                          ),
                                                        ),
                                                  ).then((_) async {
                                                    productData =
                                                        await getProducts();
                                                    setState(() {});
                                                  }),
                                              icon: Icon(
                                                Icons.edit,
                                                color: ColorsApp.secondaryColor,
                                              ),
                                            ),
                                            textInfo:
                                                'Cód: ${product['code'].toString()}',
                                          ),
                                        );
                                      },
                                    ),
                                    TextIconButtonMod1(
                                      text: "Enviar catálogo por WhatsApp",
                                      icon: Symbols.forward,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => App(
                                              selectedIndex: 3,
                                              child: MessengeList(
                                                initialText:
                                                    "Catálogo de Serviços/Produtos:\n\n" +
                                                    (productData['results']
                                                            as List)
                                                        .map(
                                                          (p) =>
                                                              "${p['name']} - R\$${p['price']}",
                                                        )
                                                        .join("\n"),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      color: ColorsApp.secondaryColor,
                                      colorLabel: ColorsApp.secondaryColor,
                                      width: double.maxFinite,
                                    ),
                                    ButtonMod1(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      text: "Fechar",
                                      colorLabel: Colors.white,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
