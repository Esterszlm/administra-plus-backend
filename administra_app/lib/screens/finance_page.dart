import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/finance_form_dialog.dart';

class FinancePage extends StatefulWidget {
  final ApiService apiService;

  const FinancePage({
    super.key,
    required this.apiService,
  });

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool loading = true;
  String message = '';
  List<dynamic> finances = [];
  List<dynamic> organizations = [];

  Future<void> loadData() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final financeData = await widget.apiService.getFinance();
      final organizationsData = await widget.apiService.getOrganizations();

      setState(() {
        finances = financeData;
        organizations = organizationsData;
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao carregar financeiro.';
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

  String tipoFormatado(dynamic valor) {
    final tipo = texto(valor);

    if (tipo == 'entrada') {
      return 'Entrada';
    }

    if (tipo == 'saida') {
      return 'Saída';
    }

    return tipo;
  }

  Color tipoCor(dynamic valor) {
    final tipo = texto(valor);

    if (tipo == 'entrada') {
      return AppColors.success;
    }

    if (tipo == 'saida') {
      return AppColors.danger;
    }

    return AppColors.textSecondary;
  }

  Future<void> openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return FinanceFormDialog(
          organizations: organizations,
          onSubmit: ({
            required String type,
            required double amount,
            required String description,
            required int organizationId,
          }) async {
            await widget.apiService.createFinance(
              type: type,
              amount: amount,
              description: description,
              organizationId: organizationId,
            );
          },
        );
      },
    );

    if (result == true) {
      showSuccess('Lançamento financeiro cadastrado com sucesso.');
      await loadData();
    }
  }

  Future<void> openEditDialog(Map<String, dynamic> finance) async {
    final id = int.tryParse(finance['id'].toString());

    if (id == null) {
      showSuccess('ID do lançamento inválido.');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return FinanceFormDialog(
          finance: finance,
          organizations: organizations,
          onSubmit: ({
            required String type,
            required double amount,
            required String description,
            required int organizationId,
          }) async {
            await widget.apiService.updateFinance(
              id: id,
              type: type,
              amount: amount,
              description: description,
              organizationId: organizationId,
            );
          },
        );
      },
    );

    if (result == true) {
      showSuccess('Lançamento financeiro atualizado com sucesso.');
      await loadData();
    }
  }

  Future<void> confirmDelete(Map<String, dynamic> finance) async {
    final id = int.tryParse(finance['id'].toString());

    if (id == null) {
      showSuccess('ID do lançamento inválido.');
      return;
    }

    final description = texto(finance['description']);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir lançamento financeiro'),
          content: Text(
            'Tem certeza que deseja excluir o lançamento "$description"?',
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
        await widget.apiService.deleteFinance(id);
        showSuccess('Lançamento financeiro excluído com sucesso.');
        await loadData();
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
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AdminTablePage(
      title: 'Financeiro',
      subtitle: 'Gestão dos lançamentos financeiros do sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhum lançamento financeiro cadastrado.',
      onRefresh: loadData,
      onNew: openCreateDialog,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Descrição')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Valor')),
        DataColumn(label: Text('Organização')),
        DataColumn(label: Text('Ações')),
      ],
      rows: finances.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(texto(item['id']))),
            DataCell(Text(texto(item['description']))),
            DataCell(
              Text(
                tipoFormatado(item['type']),
                style: TextStyle(
                  color: tipoCor(item['type']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(Text(formatarValor(item['amount']))),
            DataCell(
              Text(
                texto(item['organization_name'] ?? item['organization_id']),
              ),
            ),
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