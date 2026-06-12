import 'package:flutter/material.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/modal/modal_mod2.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/page/client.dart';
import 'package:scheduling/page/login.dart';
import 'package:scheduling/page/messenge.dart';
import 'package:scheduling/page/notify.dart';
import 'package:scheduling/page/shedulings.dart';
import 'package:searchfield/searchfield.dart';

void main() {
  runApp(const MyApp());
}

class Services {
  final String name;
  final String zip;
  Services(this.name, this.zip);
}

class App extends StatefulWidget {
  final dynamic child;
  final String title;
  final int selectedIndex;
  const App({super.key, this.child, this.title = '', this.selectedIndex = 0});

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
  late List<SearchFieldListItem<Services>> services;
  SearchFieldListItem<Services>? selectedValue;
  final TextEditingController _serviceController = TextEditingController();

  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _selectedIndex = widget.selectedIndex;
    services =
        [
          Services('Corte de cabelo', '00001'),
          Services('Barba', '00002'),
          Services('Maquiagem', '00003'),
          Services('Sobrancelha', '00004'),
        ].map((Services ct) {
          return SearchFieldListItem<Services>(
            // search will be performed on this value
            ct.name,
            // value to set in input on click, defaults to searchKey (optional)
            value: ct.zip.toString(),
            // custom object to pass in the suggestion list (optional)
            item: ct,
            // custom widget to show in the suggestion list (optional)
            child: searchChild(ct, isSelected: false),
          );
        }).toList();
    super.initState();
  }

  Widget searchChild(Services services, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        services.name,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
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
            icon: Icon(Icons.logout_outlined, color: Colors.black),
          ),
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        endDrawer: Drawer(child: SafeArea(child: DrawerTab())),
        body:
            widget.child ??
            IndexedStack(index: _selectedIndex, children: _pages),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          onPressed: () {
            _showAddModal();
          },
          child: const Icon(Icons.add, color: Colors.white, size: 30),
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
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Symbols.event,
                      color: _selectedIndex == 0 ? Colors.black : Colors.grey,
                      size: _selectedIndex == 0 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 0),
                  ),
                  IconButton(
                    icon: Icon(
                      Symbols.account_box,
                      color: _selectedIndex == 1 ? Colors.black : Colors.grey,
                      size: _selectedIndex == 1 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 1),
                  ),

                  // Em vez de um item de menu, apenas um espaço vazio onde o FAB vai flutuar por cima
                  const SizedBox(width: 40),

                  IconButton(
                    icon: ImageIcon(
                      AssetImage('assets/icons/WhatsApp.png'),
                      color: _selectedIndex == 3 ? Colors.black : Colors.grey,
                      size: _selectedIndex == 3 ? 35 : 24,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 3),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: _selectedIndex == 4 ? Colors.black : Colors.grey,
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

  void _showAddModal() {
    // Limpa a seleção anterior ao abrir o modal para um novo agendamento
    selectedValue = null;
    _serviceController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _selectedIndex == 3
            ? ModalMod2(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ButtonMod1(
                      color: Colors.black,
                      text: 'Cliente',
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                        Navigator.pop(context);
                        _showAddModal();
                      },
                    ),
                    SizedBox(height: 10),
                    ButtonMod1(
                      color: Colors.black,
                      text: 'Agendamento',
                      onPressed: () {
                        setState(() => _selectedIndex = 0);
                        Navigator.pop(context);
                        _showAddModal();
                      },
                    ),
                  ],
                ),
              )
            : ModalMod1(
                content: _selectedIndex == 0
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TextFieldMod1(
                            labelText: 'Selecione Data e Horário',
                            readOnly: true,
                            suffixIcon: Icon(Icons.calendar_month),
                          ),
                          const SizedBox(height: 10),
                          SearchField(
                            controller: _serviceController,
                            maxSuggestionBoxHeight: 300,
                            onSuggestionTap:
                                (SearchFieldListItem<Services> item) {
                                  setModalState(() {
                                   // selectedValue = item;
                                    _serviceController.text = item.searchKey;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                            onSearchTextChanged: (searchText) {
                              // filter the list with your custom search logic
                              final filter = List<SearchFieldListItem<Services>>.from(
                                    services,
                                  ).where((serviceItem) {
                                    return serviceItem.item!.name
                                            .toLowerCase()
                                            .contains(
                                              searchText.toLowerCase(),
                                            ) ||
                                        serviceItem.item!.zip.toString().contains(
                                          searchText,
                                        );
                                  }).toList();
                              return filter;
                            },
                            selectedValue: selectedValue,
                            suggestions: services,
                            suggestionState: Suggestion.expand,
                            searchInputDecoration: SearchInputDecoration(
                              label: Text('Informe o serviço'),
                              labelStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                              fillColor: Colors.grey[350],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 3.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const TextFieldMod1(labelText: 'Informe o cliente'),
                          const SizedBox(height: 10),
                          const Text(
                            'Orçamento: R\$ 0,00',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const DrawerTab({super.key});

  @override
  State<DrawerTab> createState() => _DrawerTabState();
}

class _DrawerTabState extends State<DrawerTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    maxRadius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.black),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ), // Estilo padrão/base
                          children: [
                            TextSpan(
                              text: 'Usuário: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ), // Aplica negrito apenas aqui
                            ),
                            TextSpan(
                              text:
                                  'Anônimo', // Herda o estilo padrão (cor branca, sem negrito)
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: Colors.white,
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
                            color: Colors.white,
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
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.black,
              ),
              title: Text(
                'Área do admin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            SizedBox(height: 10),
            ExpandedTile(
              theme: ExpandedTileThemeData(
                headerColor: Colors.transparent, // Cabeçalho branco
                contentBackgroundColor:
                    Colors.grey[300], // Fundo do conteúdo cinza claro
                // Remove o preenchimento padrão para os Dividers encostarem nas bordas laterais
                contentPadding: EdgeInsets.zero,
                headerPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                // 1. Quando FECHADO: Totalmente arredondado
                headerBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),

                // 2. Quando ABERTO: Arredondado apenas em cima, reto embaixo
                fullExpandedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
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
              title: const Text(
                "Relatórios",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              content: Column(mainAxisSize: MainAxisSize.min, children: []),
            ),
            SizedBox(height: 10),
            ExpandedTile(
              theme: ExpandedTileThemeData(
                headerColor: Colors.transparent, // Cabeçalho branco
                contentBackgroundColor:
                    Colors.grey[200], // Fundo do conteúdo cinza claro
                // Remove o preenchimento padrão para os Dividers encostarem nas bordas laterais
                contentPadding: EdgeInsets.zero,
                headerPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                // 1. Quando FECHADO: Totalmente arredondado
                headerBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),

                // 2. Quando ABERTO: Arredondado apenas em cima, reto embaixo
                fullExpandedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
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
              title: const Text(
                "Serviços",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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
                    title: const Text(
                      "Cadastro",
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () {},
                  ),

                  // Linha divisória entre os itens internos
                  const Divider(color: Colors.grey, height: 1, thickness: 1),

                  // Segundo Item (Consulta de preço)
                  ListTile(
                    title: const Text(
                      "Consulta de preço",
                      style: TextStyle(color: Colors.black, fontSize: 15),
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
