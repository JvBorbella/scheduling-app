import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/modal/modal_mod1.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/component/text_field/text_field_mod1.dart';
import 'package:http/http.dart' as http;
import 'package:scheduling/modals_crud/crud_customer.dart';
import 'package:scheduling/requests/customers.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientList extends StatefulWidget {
  const ClientList({super.key});

  @override
  State<ClientList> createState() => _ClientListState();
}

class _ClientListState extends State<ClientList> {
  List<dynamic> customers = [];

  TextEditingController nameController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getClients();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBarDefault(hintText: 'cliente'),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ), // Margem externa mantida aqui
                  child: CardList(
                    title: customer['name'],
                    text:
                        'Tel.: ${customer['phone']}\nE-mail: ${customer['email']}\nCPF/CNPJ: ${customer['cpf'] ?? customer['cnpj']} ',
                    textInfo: 'Cód ${customer['code']}',
                    iconButton: IconButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => CrudCustomer.modalMod1(
                          context,
                          customer['id'],
                          nameController..text = customer['name'],
                          cpfController..text = customer['cpf'],
                          emailController..text = customer['email'],
                          phoneController..text = customer['phone'],
                        ),
                      ),
                      icon: Icon(Icons.edit),
                      color: Colors.amber,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModal() {
    showDialog(
      context: context,
      builder: (context) => CrudCustomer.modalMod1(
        context,
        customers[0]['id'],
        nameController..text = customers[0]['name'],
        cpfController..text = customers[0]['cpf'],
        emailController..text = customers[0]['email'],
        phoneController..text = customers[0]['phone'],
      ),
      // ModalMod1(
      //   content: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           TextFieldMod1(
      //             controller: nameController..text = customers[0]['name'],
      //             labelText: 'Nome',
      //             width: 120,
      //           ),
      //           TextFieldMod1(
      //             controller: cpfController..text = customers[0]['cpf'],
      //             labelText: 'CPF/CNPJ',
      //             width: 120,
      //           ),
      //         ],
      //       ),
      //       SizedBox(height: 10),
      //       TextFieldMod1(
      //         controller: emailController..text = customers[0]['email'],
      //         labelText: 'Email para contato',
      //       ),
      //       SizedBox(height: 10),
      //       TextFieldMod1(
      //         controller: phoneController..text = customers[0]['phone'],
      //         labelText: 'Telefone para contato',
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Future<void> getClients() async {
    customers = await Customers().getClient();
    setState(() {});
  }

  void onRefresh() {
    getClients();
  }
}
