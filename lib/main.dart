import 'dart:convert';
import 'dart:developer';

import 'package:all_validations_br/all_validations_br.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/modal/modal_mod2.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/page/admin.dart';
import 'package:scheduling/requests/company.dart';
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

void main() {
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
];

int _selectedIndex = 0;

class _AppState extends State<App> {
  List<SearchFieldListItem<Services>> services = [];
  SearchFieldListItem<Services>? selectedValue;
  final TextEditingController _serviceController = TextEditingController();
  String _nomeUsuario = '';

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
    if (nomeUsuario != null) {
      setState(() {
        _nomeUsuario = nomeUsuario;
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
          child: SafeArea(child: DrawerTab(nomeUsuario: _nomeUsuario)),
        ),
        body:
            widget.child ??
            IndexedStack(index: _selectedIndex, children: _pages),
        floatingActionButton: FloatingActionButton(
          backgroundColor: ColorsApp.secondaryColor,
          shape: const CircleBorder(),
          onPressed: () {
            showAddModal();
          },
          child: Icon(Icons.add, color: ColorsApp.primaryColor, size: 30),
        ),
        // Posiciona o FAB perfeitamente no centro cortando/sobrepondo a barra
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
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
              color: ColorsApp.secondaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Symbols.event,
                      color: _selectedIndex == 0
                          ? ColorsApp.primaryColor
                          : Colors.grey,
                      size: _selectedIndex == 0 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 0),
                  ),
                  IconButton(
                    icon: Icon(
                      Symbols.account_box,
                      color: _selectedIndex == 1
                          ? ColorsApp.primaryColor
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
            : ModalMod1(
                title: _selectedIndex == 0 ? 'Confirmar Agendamento' : null,
                textButton: _selectedIndex == 0 ? 'Confirmar e Pagar' : null,
                onPressed: _selectedIndex == 0
                    ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('access_token');
                        await dotenv.load(fileName: ".env");
                        final baseUrl = dotenv.env['BASE_URL']!;
                        try {
                          var response = await http.post(
                            Uri.parse(baseUrl + Endpoints.insert),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                              'X-TENANT-ID':
                                  '4368297b-944d-4bc5-827c-333cfdf012f9',
                            },
                            body: jsonEncode({
                              "tabela": "orders",
                              "values": {
                                "tenant_id":
                                    "4368297b-944d-4bc5-827c-333cfdf012f9",
                                "company_id":
                                    "a01c0001-944d-4bc5-827c-333cfdf012f9",
                                "customer_id":
                                    "c002bb44-4444-47dc-9f0e-b7e6718cfd91",
                                "created_at": _dateTimeController.text.isEmpty
                                    ? DateTime.now().toString()
                                    : _dateTimeController.text,
                              },
                            }),
                          );
                          if (response.statusCode == 200) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Agendado!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao agendar!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setState(() {
                          Shedulings();
                        });
                        // // Exibe indicador de carregamento
                        // showDialog(
                        //   context: context,
                        //   barrierDismissible: false,
                        //   builder: (context) => const Center(
                        //     child: CircularProgressIndicator(
                        //       color: ColorsApp.secondaryColor,
                        //     ),
                        //   ),
                        // );

                        // try {
                        //   final paymentService = PaymentService(
                        //     tenantId: 'tenant-mat-construcao',
                        //   );
                        //   final clientName = _clientController.text.isNotEmpty
                        //       ? _clientController.text
                        //       : 'Matheus Stevam';
                        //   final double amountVal =
                        //       double.tryParse(_amountController.text) ?? 0.10;

                        //   String? vaultToken;
                        //   if (selectedPaymentType == 'credit_card') {
                        //     if (_cardNumberController.text.isEmpty ||
                        //         _cvvController.text.isEmpty ||
                        //         _expiryMonthController.text.isEmpty ||
                        //         _expiryYearController.text.isEmpty ||
                        //         _cardholderController.text.isEmpty ||
                        //         _cpfController.text.isEmpty) {
                        //       throw Exception(
                        //         'Por favor, preencha todos os dados do cartão.',
                        //       );
                        //     }

                        //     final cardDetails = CardDetails(
                        //       cardNumber: _cardNumberController.text,
                        //       securityCode: _cvvController.text,
                        //       expirationMonth: _expiryMonthController.text,
                        //       expirationYear: _expiryYearController.text,
                        //       cardholderName: _cardholderController.text,
                        //       documentNumber: _cpfController.text,
                        //       documentType: 'CPF',
                        //     );

                        //     final tokenRes = await paymentService.tokenizeVault(
                        //       cardDetails,
                        //     );
                        //     vaultToken = tokenRes.vaultToken;
                        //   }

                        //   final payload = PaymentPayload(
                        //     type: selectedPaymentType,
                        //     orderId: '0064CC76-52CF-45E7-BECD-4B5E42C54C60',
                        //     paymentMethodId:
                        //         '00ff2e60-4efb-11f1-b623-225ba6c9c0a5',
                        //     amount: amountVal,
                        //     customer: CustomerPayload(
                        //       email: 'borbella31@gmail.com',
                        //       name: clientName,
                        //       document: '16433829775',
                        //       phone: '21979249199',
                        //     ),
                        //     vaultToken: vaultToken,
                        //     // installments: selectedPaymentType == 'credit_card'
                        //     //     ? 1
                        //     //     : null,
                        //     //description: 'Serviço de agendamento',
                        //   );

                        //   final paymentResponse = await paymentService
                        //       .processPayment(payload);

                        //   // Fecha loading e fecha modal
                        //   if (context.mounted)
                        //     Navigator.pop(context); // fecha loading
                        //   if (context.mounted)
                        //     Navigator.pop(context); // fecha modal

                        //   // Exibe diálogo de sucesso
                        //   if (context.mounted) {
                        //     showDialog(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         title: const Row(
                        //           children: [
                        //             Icon(
                        //               Icons.check_circle,
                        //               color: Colors.green,
                        //             ),
                        //             SizedBox(width: 8),
                        //             Text('Sucesso'),
                        //           ],
                        //         ),
                        //         content: Column(
                        //           mainAxisSize: MainAxisSize.min,
                        //           crossAxisAlignment: CrossAxisAlignment.start,
                        //           children: [
                        //             const Text(
                        //               'Pagamento processado com sucesso!',
                        //             ),
                        //             const SizedBox(height: 10),
                        //             Text(
                        //               'ID: ${paymentResponse['data']?['id'] ?? paymentResponse['id'] ?? 'N/A'}',
                        //             ),
                        //             Text(
                        //               'Status: ${paymentResponse['data']?['status'] ?? paymentResponse['status'] ?? 'approved'}',
                        //             ),
                        //             if (selectedPaymentType == 'pix') ...[
                        //               const SizedBox(height: 10),
                        //               const Text(
                        //                 'Copia e Cola Pix:',
                        //                 style: TextStyle(
                        //                   fontWeight: FontWeight.bold,
                        //                 ),
                        //               ),
                        //               SelectableText(
                        //                 paymentResponse['data']?['qr_code'] ??
                        //                     '00020101021243650016br.gov.bcb.pix...',
                        //                 style: const TextStyle(
                        //                   fontSize: 10,
                        //                   fontFamily: 'monospace',
                        //                 ),
                        //               ),
                        //             ],
                        //           ],
                        //         ),
                        //         actions: [
                        //           TextButton(
                        //             onPressed: () => Navigator.pop(context),
                        //             child: const Text(
                        //               'Fechar',
                        //               style: TextStyle(color: ColorsApp.secondaryColor),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     );
                        //   }
                        // } catch (err) {
                        //   if (context.mounted)
                        //     Navigator.pop(context); // fecha loading

                        //   // Exibe erro
                        //   if (context.mounted) {
                        //     showDialog(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         title: const Row(
                        //           children: [
                        //             Icon(Icons.error, color: Colors.red),
                        //             SizedBox(width: 8),
                        //             Text('Erro no Pagamento'),
                        //           ],
                        //         ),
                        //         content: Text(
                        //           err.toString().replaceAll('Exception: ', ''),
                        //         ),
                        //         actions: [
                        //           TextButton(
                        //             onPressed: () => Navigator.pop(context),
                        //             child: const Text(
                        //               'Voltar',
                        //               style: TextStyle(color: ColorsApp.secondaryColor),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     );
                        //   }
                        // }
                      }
                    : null,
                content: _selectedIndex == 0
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFieldMod1(
                              labelText: 'Selecione Data e Horário',
                              readOnly: true,
                              controller: _dateTimeController,
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  final DateTime? result =
                                      await showOmniDateTimePicker(
                                        context: context,
                                        is24HourMode: true,
                                      );
                                  setModalState(() {
                                    _dateTimeController.text = result
                                        .toString();
                                  });
                                },
                                icon: Icon(Icons.calendar_month),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SearchField(
                              controller: _serviceController,
                              maxSuggestionBoxHeight: 300,
                              onSuggestionTap:
                                  (SearchFieldListItem<Services> item) {
                                    setModalState(() {
                                      selectedValue = item;
                                      _serviceController.text = item.searchKey;
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                              onSearchTextChanged: (searchText) {
                                final filter =
                                    List<SearchFieldListItem<Services>>.from(
                                      services,
                                    ).where((serviceItem) {
                                      return serviceItem.item!.name
                                              .toLowerCase()
                                              .contains(
                                                searchText.toLowerCase(),
                                              ) ||
                                          serviceItem.item!.code
                                              .toString()
                                              .contains(searchText);
                                    }).toList();
                                return filter;
                              },
                              selectedValue: selectedValue,
                              suggestions: services,
                              suggestionState: Suggestion.expand,
                              searchInputDecoration: SearchInputDecoration(
                                label: const Text('Informe o serviço'),
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                                fillColor: Colors.grey[350],
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: ColorsApp.secondaryColor,
                                    width: 3.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFieldMod1(
                              controller: _clientController,
                              labelText: 'Informe o cliente',
                            ),
                            const SizedBox(height: 10),
                            TextFieldMod1(
                              controller: _amountController,
                              labelText: 'Valor do Serviço (R\$)',
                            ),
                            // const SizedBox(height: 10),
                            // const Align(
                            //   alignment: Alignment.centerLeft,
                            //   child: Text(
                            //     'Forma de Pagamento',
                            //     style: TextStyle(
                            //       fontWeight: FontWeight.bold,
                            //       fontSize: 10,
                            //       color: Colors.grey,
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(height: 5),
                            // DropdownButtonFormField<String>(
                            //   value: selectedPaymentType,
                            //   decoration: InputDecoration(
                            //     fillColor: Colors.grey[350],
                            //     filled: true,
                            //     contentPadding: const EdgeInsets.symmetric(
                            //       horizontal: 12,
                            //       vertical: 8,
                            //     ),
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(12.0),
                            //       borderSide: const BorderSide(
                            //         color: ColorsApp.secondaryColor,
                            //         width: 3.0,
                            //       ),
                            //     ),
                            //   ),
                            //   items: const [
                            //     DropdownMenuItem(
                            //       value: 'pix',
                            //       child: Text('Pix'),
                            //     ),
                            //     DropdownMenuItem(
                            //       value: 'credit_card',
                            //       child: Text('Cartão de Crédito'),
                            //     ),
                            //     DropdownMenuItem(
                            //       value: 'boleto',
                            //       child: Text('Boleto'),
                            //     ),
                            //   ],
                            //   onChanged: (val) {
                            //     setModalState(() {
                            //       selectedPaymentType = val ?? 'pix';
                            //     });
                            //   },
                            // ),
                            // if (selectedPaymentType == 'credit_card') ...[
                            //   const SizedBox(height: 10),
                            //   TextFieldMod1(
                            //     controller: _cardNumberController,
                            //     labelText: 'Número do Cartão',
                            //     inputFormatters: [
                            //       FilteringTextInputFormatter.digitsOnly,
                            //       CartaoBancarioInputFormatter(),
                            //     ],
                            //   ),
                            //   const SizedBox(height: 10),
                            //   TextFieldMod1(
                            //     controller: _cardholderController,
                            //     labelText: 'Nome Impresso',
                            //   ),
                            //   const SizedBox(height: 10),
                            //   Row(
                            //     children: [
                            //       Expanded(
                            //         child: TextFieldMod1(
                            //           controller: _expiryMonthController,
                            //           labelText: 'Mês Exp. (MM)',
                            //         ),
                            //       ),
                            //       const SizedBox(width: 8),
                            //       Expanded(
                            //         child: TextFieldMod1(
                            //           controller: _expiryYearController,
                            //           labelText: 'Ano Exp. (AAAA)',
                            //         ),
                            //       ),
                            //       const SizedBox(width: 8),
                            //       Expanded(
                            //         child: TextFieldMod1(
                            //           controller: _cvvController,
                            //           labelText: 'CVV',
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            //   const SizedBox(height: 10),
                            //   TextFieldMod1(
                            //     controller: _cpfController,
                            //     labelText: 'CPF/CNPJ do Titular',
                            //     inputFormatters: [
                            //       FilteringTextInputFormatter.digitsOnly,
                            //       CpfOuCnpjFormatter(),
                            //     ],
                            //   ),
                            // ],
                          ],
                        ),
                      )
                    : _selectedIndex == 1
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextFieldMod1(labelText: 'Nome', width: 100),
                              TextFieldMod1(labelText: 'CPF/CNPJ', width: 100),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextFieldMod1(labelText: 'Email para contato'),
                          SizedBox(height: 10),
                          TextFieldMod1(labelText: 'Telefone para contato'),
                        ],
                      )
                    : _selectedIndex == 4
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
  Future<void> getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final empresaId = prefs.getString("empresa_id");
    if (empresaId != null) {
      CompanyRequest().getCompany().then((response) async {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          log(response.body.toString());
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

  @override
  void initState() {
    super.initState();
    getCompany();
    ColorsApp.setColors();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agendamentos',
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
  const DrawerTab({super.key, required this.nomeUsuario});

  @override
  State<DrawerTab> createState() => _DrawerTabState();
}

class _DrawerTabState extends State<DrawerTab> {
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
                              text:
                                  'João Couiffeir', // Herda o estilo padrão (cor branca, sem negrito)
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
                //Navigator.pop(context); // Fechar o drawer
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
                      "Cadastro",
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
                      showDialog(
                        context: context,
                        builder: (context) => ModalMod1(
                          title: 'Cadastro',
                          content: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 10.0,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: ColorsApp.secondaryColor,
                                  child: Icon(
                                    Icons.image,
                                    color: ColorsApp.primaryColor,
                                  ),
                                ),
                                TextFieldMod1(
                                  controller: _nameServiceController,
                                  labelText: 'Nome',
                                  keyboardType: TextInputType.text,
                                ),
                                TextFieldMod1(
                                  controller: _descripTionServiceController,
                                  labelText: 'Descrição',
                                  keyboardType: TextInputType.text,
                                ),
                                TextFieldMod1(
                                  controller: _priceServiceController,
                                  labelText: 'Preço',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [CurrencyMask()],
                                ),
                              ],
                            ),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('access_token');
                            await dotenv.load(fileName: ".env");
                            final baseUrl = dotenv.env['BASE_URL']!;
                            try {
                              final response = await http.post(
                                Uri.parse(baseUrl + Endpoints.insert),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                  'X-TENANT-ID':
                                      '${prefs.getString('empresa_id')}',
                                },
                                body: jsonEncode({
                                  "tabela": "products",
                                  "values": {
                                    "tenant_id":
                                        "${prefs.getString("tenant_id")}",
                                    "company_id":
                                        "${prefs.getString("company_id")}",
                                    "name": _nameServiceController.text,
                                    "description":
                                        _descripTionServiceController.text,
                                    "price": _priceServiceController.text
                                        .replaceAll(',', '.')
                                        .replaceAll('R\$', ''),
                                  },
                                }),
                              );
                              if (response.statusCode == 200) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Produto cadastrado com sucesso!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                print(response.body);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.body.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),

                  // Linha divisória entre os itens internos
                  const Divider(color: Colors.grey, height: 1, thickness: 1),

                  // Segundo Item (Consulta de preço)
                  ListTile(
                    title: Text(
                      "Consulta de preço",
                      style: TextStyle(
                        color: ColorsApp.secondaryColor,
                        fontSize: 15,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () {},
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
