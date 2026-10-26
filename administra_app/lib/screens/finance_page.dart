import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/finance_form_dialog.dart';

class FinancePage extends StatefulWidget {
  final ApiService apiService;
  final bool isAdmin;
  final Set<String> permissions;

  const FinancePage({
    super.key,
    required this.apiService,
    this.isAdmin = false,
    this.permissions = const <String>{},
  });

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool _can(String permission) =>
      widget.isAdmin || widget.permissions.contains(permission);
  bool loading = true;
  String message = '';
  List<dynamic> finances = [];
  List<dynamic> organizations = [];
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final financeData = await widget.apiService.getFinance();
      // finance_view e organizations_view são permissões independentes.
      List<dynamic> organizationsData = [];
      try {
        organizationsData = await widget.apiService.getOrganizations();
      } catch (_) {
        organizationsData = [];
      }

      // Financeiro e Usuários usam permissões distintas. Se a conta não puder
      // listar usuários, a consulta financeira continua funcionando.
      List<dynamic> usersData = [];
      try {
        usersData = await widget.apiService.getUsers();
      } catch (_) {
        usersData = [];
      }

      if (!mounted) return;
      setState(() {
        finances = financeData;
        organizations = organizationsData;
        users = usersData;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String tipoFormatado(dynamic valor) {
    final tipo = texto(valor);
    if (tipo == 'entrada') return 'Entrada';
    if (tipo == 'saida') return 'Saída';
    return tipo;
  }

  Color tipoCor(dynamic valor) {
    final tipo = texto(valor);
    if (tipo == 'entrada') return AppColors.success;
    if (tipo == 'saida') return AppColors.danger;
    return AppColors.textSecondary;
  }

  String usuarioFormatado(Map<String, dynamic> finance) {
    final userName = finance['user_name']?.toString();
    if (userName != null && userName.trim().isNotEmpty) {
      return userName;
    }

    final userId = finance['user_id'];
    if (userId == null) return 'Sem usuário';

    for (final item in users) {
      if (item is Map && item['id'].toString() == userId.toString()) {
        return item['name']?.toString() ?? 'Usuário #$userId';
      }
    }
    return 'Usuário #$userId';
  }

  Future<void> openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FinanceFormDialog(
        organizations: organizations,
        users: users,
        onSubmit:
            ({
              required String type,
              required double amount,
              required String description,
              required int organizationId,
              int? userId,
            }) async {
              await widget.apiService.createFinance(
                type: type,
                amount: amount,
                description: description,
                organizationId: organizationId,
                userId: userId,
              );
            },
      ),
    );

    if (!mounted || result != true) return;
    await loadData();
    if (message.isEmpty) {
      showMessage('Lançamento financeiro cadastrado com sucesso.');
    }
  }

  Future<void> openEditDialog(Map<String, dynamic> finance) async {
    final id = int.tryParse(finance['id'].toString());
    if (id == null) {
      showMessage('ID do lançamento inválido.');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FinanceFormDialog(
        finance: finance,
        organizations: organizations,
        users: users,
        onSubmit:
            ({
              required String type,
              required double amount,
              required String description,
              required int organizationId,
              int? userId,
            }) async {
              await widget.apiService.updateFinance(
                id: id,
                type: type,
                amount: amount,
                description: description,
                organizationId: organizationId,
                userId: userId,
              );
            },
      ),
    );

    if (!mounted || result != true) return;
    await loadData();
    if (message.isEmpty) {
      showMessage('Lançamento financeiro atualizado com sucesso.');
    }
  }

  Future<void> confirmDelete(Map<String, dynamic> finance) async {
    final id = int.tryParse(finance['id'].toString());
    if (id == null) {
      showMessage('ID do lançamento inválido.');
      return;
    }

    final description = texto(finance['description']);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lançamento financeiro'),
        content: Text(
          'Tem certeza que deseja excluir o lançamento "$description"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted || result != true) return;

    try {
      await widget.apiService.deleteFinance(id);
      if (!mounted) return;
      await loadData();
      if (message.isEmpty) {
        showMessage('Lançamento financeiro excluído com sucesso.');
      }
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
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
      onNew: _can('finance_create') ? openCreateDialog : null,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Descrição')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Valor')),
        DataColumn(label: Text('Organização')),
        DataColumn(label: Text('Usuário vinculado')),
        DataColumn(label: Text('Ações')),
      ],
      rows: finances.whereType<Map>().map((value) {
        final item = Map<String, dynamic>.from(value);
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
              Text(texto(item['organization_name'] ?? item['organization_id'])),
            ),
            DataCell(Text(usuarioFormatado(item))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_can('finance_edit'))
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => openEditDialog(item),
                    ),
                  if (_can('finance_delete'))
                    IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => confirmDelete(item),
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
