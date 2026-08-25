import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';

class OrganizationsPage extends StatefulWidget {
  final ApiService apiService;

  const OrganizationsPage({
    super.key,
    required this.apiService,
  });

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  bool loading = true;
  String message = '';
  List<dynamic> organizations = [];

  Future<void> loadOrganizations() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final data = await widget.apiService.getOrganizations();

      setState(() {
        organizations = data;
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao carregar organizações.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void showActionMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void initState() {
    super.initState();
    loadOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    return AdminTablePage(
      title: 'Organizações',
      subtitle: 'Gestão das organizações cadastradas no sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhuma organização cadastrada.',
      onRefresh: loadOrganizations,
      onNew: () => showActionMessage('Cadastro de organização será criado na próxima etapa.'),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Nome')),
        DataColumn(label: Text('Documento')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Cidade')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Responsável')),
        DataColumn(label: Text('Ações')),
      ],
      rows: organizations.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(texto(item['id']))),
            DataCell(Text(texto(item['name']))),
            DataCell(Text(texto(item['document']))),
            DataCell(Text(texto(item['type']))),
            DataCell(Text(texto(item['city']))),
            DataCell(Text(texto(item['state']))),
            DataCell(Text(texto(item['responsible_name']))),
            DataCell(
              Row(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit),
                    onPressed: () => showActionMessage('Edição será criada na próxima etapa.'),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => showActionMessage('Exclusão será criada na próxima etapa.'),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}