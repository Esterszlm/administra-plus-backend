import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/organization_form_dialog.dart';

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

  void showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return OrganizationFormDialog(
          onSubmit: ({
            required String name,
            required String type,
            required String document,
            required String address,
            required String city,
            required String state,
            required String responsibleName,
          }) async {
            await widget.apiService.createOrganization(
              name: name,
              type: type,
              document: document,
              address: address,
              city: city,
              state: state,
              responsibleName: responsibleName,
            );
          },
        );
      },
    );

    if (result == true) {
      showSuccess('Organização cadastrada com sucesso.');
      await loadOrganizations();
    }
  }

  Future<void> openEditDialog(Map<String, dynamic> organization) async {
    final id = int.tryParse(organization['id'].toString());

    if (id == null) {
      showSuccess('ID da organização inválido.');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return OrganizationFormDialog(
          organization: organization,
          onSubmit: ({
            required String name,
            required String type,
            required String document,
            required String address,
            required String city,
            required String state,
            required String responsibleName,
          }) async {
            await widget.apiService.updateOrganization(
              id: id,
              name: name,
              type: type,
              document: document,
              address: address,
              city: city,
              state: state,
              responsibleName: responsibleName,
            );
          },
        );
      },
    );

    if (result == true) {
      showSuccess('Organização atualizada com sucesso.');
      await loadOrganizations();
    }
  }

  Future<void> confirmDelete(Map<String, dynamic> organization) async {
    final id = int.tryParse(organization['id'].toString());

    if (id == null) {
      showSuccess('ID da organização inválido.');
      return;
    }

    final name = texto(organization['name']);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir organização'),
          content: Text(
            'Tem certeza que deseja excluir a organização "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await widget.apiService.deleteOrganization(id);
        showSuccess('Organização excluída com sucesso.');
        await loadOrganizations();
      } catch (e) {
        showSuccess(
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
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
      onNew: openCreateDialog,
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
                    onPressed: () {
                      openEditDialog(
                        Map<String, dynamic>.from(item),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      confirmDelete(
                        Map<String, dynamic>.from(item),
                      );
                    },
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