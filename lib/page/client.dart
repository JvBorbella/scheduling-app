import 'package:flutter/material.dart';
import 'package:scheduling/component/card/card_list.dart';
import 'package:scheduling/component/card/dynamic_card.dart';
import 'package:scheduling/component/text_field/search_bar.dart';
import 'package:scheduling/function/delete_function.dart';
import 'package:scheduling/function/filter_function.dart';
import 'package:scheduling/modals_crud/crud_customer.dart';
import 'package:scheduling/requests/customers.dart';

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
  TextEditingController cepController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController neighborhoodController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController complementController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getClients();
  }

  String normalizeString(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[/]'), '');
  }

  List<dynamic> filteredData = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBarDefault(
            controller: searchController,
            hintText: 'cliente',
            onPressedSearch: () => search(searchController.text),
            onPressedFilter: () => showDynamicFilterModal(
                  context: context,
                  table: 'persons',
                  columns: customers[0]['metadata'],
                ).then((value) {
                  if (value != null) {
                    setState(() {
                      filteredData = value['results'];
                    });
                  }
                }),
          ),
          SizedBox(height: 20),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => getClients(),
              strokeWidth: 2,
              child: ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final customer = filteredData[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DynamicCard(
                      remove: false,
                      colorRight: Colors.orange,
                      colorLeft: Colors.red,
                      child: CardList(
                        title: customer['name'],
                        text:
                            'Tel.: ${customer['phone']}\nE-mail: ${customer['email']}\nCPF/CNPJ: ${customer['cpf'] ?? customer['cnpj']} ',
                        textInfo: 'Cód ${customer['code']}',
                        iconButton: IconButton(
                          onPressed: () => dialogEdit(customer),
                          icon: Icon(Icons.edit),
                          color: Colors.amber,
                        ),
                      ),
                      right: () async {
                        await dialogEdit(customer);
                        onRefresh();
                      },
                      left: () async {
                        bool response = await deleteData(
                          customer,
                          context,
                          'persons',
                        );
                        if (response) {
                          onRefresh();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> dialogEdit(customer) async {
    await showDialog(
      context: context,
      builder: (context) => CrudCustomer.modalMod1(
        context,
        customer['persons_id'],
        nameController..text = customer['name'] ?? '',
        cpfController..text = customer['cpf'] ?? '',
        emailController..text = customer['email'] ?? '',
        phoneController..text = customer['phone'] ?? '',
        cepController..text = customer['zip_code'] ?? '',
        streetController..text = customer['street'] ?? '',
        neighborhoodController..text = customer['neighborhood'] ?? '',
        numberController..text = customer['number'] ?? '',
        complementController..text = customer['complement'] ?? '',
        cityController..text = customer['city'] ?? '',
        stateController..text = customer['state'] ?? '',
      ),
    );
  }

  Future<void> search(String query) async {
    setState(() {
      if (query.isEmpty) {
        filteredData = List.from(customers);
      } else {
        filteredData = customers.where((row) {
          return row.values.any(
            (value) => normalizeString(value.toString()).contains(
              normalizeString(query),
            ),
          );
        }).toList();
      }
    });
  }

  Future<void> getClients() async {
    customers = await Customers().getClient();
    filteredData = customers;
    setState(() {});
  }

  Future<void> onRefresh() async {
    setState(() {});
  }
}
