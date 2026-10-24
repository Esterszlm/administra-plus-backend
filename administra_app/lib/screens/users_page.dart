import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/user_form_dialog.dart';
import '../widgets/user_finance_dialog.dart';

class UsersPage extends StatefulWidget {
  final ApiService apiService;

  const UsersPage({super.key, required this.apiService});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _loading = true;
  String _message = '';

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _organizations = [];

  String _statusFilter = 'todos';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================================
  // CARREGAMENTO DE DADOS
  // ==========================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final usersData = await widget.apiService.getUsers();
      final organizationsData = await widget.apiService.getOrganizations();

      if (!mounted) return;

      setState(() {
        _users = usersData
            .whereType<Map>()
            .map((value) => Map<String, dynamic>.from(value))
            .toList();

        _organizations = organizationsData
            .whereType<Map>()
            .map((value) => Map<String, dynamic>.from(value))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ==========================================================
  // CONSULTAR FINANCEIRO DO USUÁRIO
  // ==========================================================

  Future<void> _openFinance(Map<String, dynamic> user) async {
    final id = int.tryParse(user['id'].toString());

    if (id == null) {
      _showMessage('ID do usuário inválido.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => UserFinanceDialog(
        apiService: widget.apiService,
        userId: id,
        userName: user['name']?.toString() ?? 'Usuário #$id',
      ),
    );
  }

  // ==========================================================
  // CADASTRAR USUÁRIO
  // ==========================================================

  Future<void> _createUser() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(
        organizations: _organizations,
        onSubmit:
            ({
              required String name,
              required String email,
              required String password,
              required String role,
              int? organizationId,
            }) async {
              await widget.apiService.createUser(
                name: name,
                email: email,
                password: password,
                role: role,
                organizationId: organizationId,
              );
            },
      ),
    );

    if (!mounted || saved != true) return;

    await _loadData();

    if (_message.isEmpty) {
      _showMessage('Usuário cadastrado com sucesso.');
    }
  }

  // ==========================================================
  // EDITAR USUÁRIO
  // ==========================================================

  Future<void> _editUser(Map<String, dynamic> user) async {
    final id = int.tryParse(user['id'].toString());

    if (id == null) {
      _showMessage('ID do usuário inválido.');
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(
        user: user,
        organizations: _organizations,
        onSubmit:
            ({
              required String name,
              required String email,
              required String password,
              required String role,
              int? organizationId,
            }) async {
              await widget.apiService.updateUser(
                id: id,
                name: name,
                email: email,
                role: role,
                organizationId: organizationId,
              );
            },
      ),
    );

    if (!mounted || saved != true) return;

    await _loadData();

    if (_message.isEmpty) {
      _showMessage('Usuário atualizado com sucesso.');
    }
  }

  // ==========================================================
  // SITUAÇÃO DO USUÁRIO
  // ==========================================================

  bool _isActive(Map<String, dynamic> user) {
    return user['is_active'] != false;
  }

  // ==========================================================
  // FORMATAÇÃO DE DATAS
  // ==========================================================

  String _dateLabel(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) {
      return 'Não registrada';
    }

    final original = raw.toString();

    // Datas do backend estão em UTC, sem sufixo de fuso.
    final utcText = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(original)
        ? original
        : '${original}Z';

    final date = DateTime.tryParse(utcText)?.toLocal();

    if (date == null) {
      return 'Data inválida';
    }

    String n(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${n(date.day)}/${n(date.month)}/${date.year} '
        '${n(date.hour)}:${n(date.minute)}';
  }

  // ==========================================================
  // DESATIVAR USUÁRIO
  // ==========================================================

  Future<void> _deactivateUser(Map<String, dynamic> user) async {
    final id = int.tryParse(user['id'].toString());

    if (id == null) return;

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Desativar usuário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desativar ${user['name']}? '
                'Os lançamentos financeiros e o histórico '
                'serão preservados.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLength: 500,
                minLines: 2,
                maxLines: 3,
                onChanged: (_) {
                  setDialogState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Motivo da desativação *',
                  hintText: 'Exemplo: Desligamento da organização',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: controller.text.trim().length < 3
                  ? null
                  : () {
                      Navigator.pop(dialogContext, controller.text.trim());
                    },
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Desativar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (!mounted || reason == null) return;

    try {
      await widget.apiService.deactivateUser(id, reason);

      if (!mounted) return;

      await _loadData();

      if (_message.isEmpty) {
        _showMessage('Usuário desativado; histórico preservado.');
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ==========================================================
  // REATIVAR USUÁRIO
  // ==========================================================

  Future<void> _reactivateUser(Map<String, dynamic> user) async {
    final id = int.tryParse(user['id'].toString());

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reativar usuário'),
        content: Text(
          'Reativar ${user['name']}? '
          'A conta poderá voltar a fazer login.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Reativar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await widget.apiService.reactivateUser(id);

      if (!mounted) return;

      await _loadData();

      if (_message.isEmpty) {
        _showMessage('Usuário reativado com sucesso.');
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ==========================================================
  // INTERFACE E FILTROS
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _users.where((user) {
      if (_statusFilter == 'ativos') {
        return _isActive(user);
      }

      if (_statusFilter == 'desativados') {
        return !_isActive(user);
      }

      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              const Text(
                'Situação:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'ativos', child: Text('Ativos')),
                  DropdownMenuItem(
                    value: 'desativados',
                    child: Text('Desativados'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statusFilter = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 14),
              Text('${visibleUsers.length} usuário(s)'),
            ],
          ),
        ),

        // ==================================================
        // TABELA DE USUÁRIOS
        // ==================================================
        Expanded(
          child: AdminTablePage(
            title: 'Usuários',
            subtitle: 'Cadastro e histórico de usuários.',
            loading: _loading,
            message: _message,
            emptyMessage: 'Nenhum usuário encontrado para este filtro.',
            onRefresh: _loadData,
            onNew: _createUser,

            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Nome (financeiro)')),
              DataColumn(label: Text('E-mail')),
              DataColumn(label: Text('Situação')),
              DataColumn(label: Text('Cadastrado em')),
              DataColumn(label: Text('Última desativação')),
              DataColumn(label: Text('Último motivo')),
              DataColumn(label: Text('Perfil')),
              DataColumn(label: Text('Organização')),
              DataColumn(label: Text('Ações')),
            ],

            rows: visibleUsers.map((user) {
              final active = _isActive(user);

              final reason = user['deactivation_reason']?.toString() ?? '';

              return DataRow(
                cells: [
                  // ID
                  DataCell(Text(user['id'].toString())),

                  // NOME: PESQUISÁVEL, EXPORTÁVEL E CLICÁVEL
                  DataCell(
                    Text(
                      user['name']?.toString() ?? '-',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () => _openFinance(user),
                  ),

                  // E-MAIL
                  DataCell(Text(user['email']?.toString() ?? '-')),

                  // SITUAÇÃO
                  DataCell(
                    Chip(
                      label: Text(active ? 'Ativo' : 'Desativado'),
                      backgroundColor: active
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      labelStyle: TextStyle(
                        color: active
                            ? Colors.green.shade800
                            : Colors.deepOrange.shade800,
                      ),
                    ),
                  ),

                  // DATA DE CADASTRO
                  DataCell(Text(_dateLabel(user['created_at']))),

                  // DATA DA ÚLTIMA DESATIVAÇÃO
                  DataCell(
                    Text(
                      user['deactivated_at'] == null
                          ? '-'
                          : _dateLabel(user['deactivated_at']),
                    ),
                  ),

                  // MOTIVO DA ÚLTIMA DESATIVAÇÃO
                  DataCell(
                    Tooltip(
                      message: reason.isEmpty
                          ? 'Sem motivo registrado'
                          : reason,
                      child: SizedBox(
                        width: 180,
                        child: Text(
                          reason.isEmpty ? '-' : reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // PERFIL
                  DataCell(
                    Text(
                      user['role'] == 'admin'
                          ? 'Administrador'
                          : 'Visualizador',
                    ),
                  ),

                  // ORGANIZAÇÃO
                  DataCell(
                    Text(
                      user['organization_name']?.toString() ??
                          'Sem organização',
                    ),
                  ),

                  // AÇÕES
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                              'Consultar financeiro (histórico preservado)',
                          icon: const Icon(Icons.receipt_long_outlined),
                          onPressed: () {
                            _openFinance(user);
                          },
                        ),

                        IconButton(
                          tooltip: 'Editar cadastro',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            _editUser(user);
                          },
                        ),

                        IconButton(
                          tooltip: active
                              ? 'Desativar (preserva o histórico)'
                              : 'Reativar',
                          icon: Icon(
                            active
                                ? Icons.person_off_outlined
                                : Icons.person_add_alt_1_outlined,
                          ),
                          onPressed: () {
                            if (active) {
                              _deactivateUser(user);
                            } else {
                              _reactivateUser(user);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
