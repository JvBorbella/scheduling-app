import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scheduling/component/button/button_mod1.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/modal/modal_mod2.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:scheduling/page/chat.dart';
import 'package:scheduling/page/client.dart';
import 'package:scheduling/page/login.dart';
import 'package:scheduling/page/messenge.dart';
import 'package:scheduling/page/notify.dart';
import 'package:scheduling/page/shedulings.dart';

void main() {
  runApp(const MyApp());
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
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      endDrawer: Drawer(),
      body:
          widget.child ?? IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color.fromRGBO(189, 189, 189, 1), width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  // Ignora o clique no índice 2 (o "buraco" do botão central)
                  if (index != 2) {
                    setState(() => _selectedIndex = index);
                  }
                },
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Symbols.event), label: ''),
                  BottomNavigationBarItem(
                    icon: Icon(Symbols.account_box),
                    label: '',
                  ),
                  // Placeholder vazio para manter o layout
                  BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
                  BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/icons/WhatsApp.png')),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: '',
                  ),
                ],
                selectedLabelStyle: TextStyle(fontSize: 10),
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.grey,
                selectedIconTheme: const IconThemeData(size: 35),
              ),
            ),
            // O botão por cima (central)
            Positioned(
              top: -22, // ajuste esse valor até “encostar” no topo
              child: GestureDetector(
                onTap: _showAddModal,
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddModal() {
    showDialog(
      context: context,
      builder: (context) => _selectedIndex == 3
          ? ModalMod2(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ButtonMod1(
                    color: Colors.black,
                    text: 'Cliente',
                    onPressed: () {
                      _selectedIndex = 1;
                      _showAddModal();
                    },
                  ),
                  SizedBox(height: 10),
                  ButtonMod1(
                    color: Colors.black,
                    text: 'Agendamento',
                    onPressed: () {
                      _selectedIndex = 0;
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
                        const TextFieldMod1(labelText: 'Informe o serviço'),
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
        colorScheme: .fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const Login()
    );
  }
}
