import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/user_finance_dialog.dart';
import '../widgets/user_form_dialog.dart';
import '../widgets/user_permissions_dialog.dart';

/// Gestão de usuários em layout compacto.
/// Pesquisa e exportação utilizam os dados, não os widgets da tabela.
class UsersPage extends StatefulWidget {
  final ApiService apiService;
  final bool isAdmin;
  final Set<String> permissions;

  const UsersPage({
    super.key,
    required this.apiService,
    this.isAdmin = false,
    this.permissions = const <String>{},
  });

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _exporting = false;
  String _message = '';
  String _statusFilter = 'todos';
  String _searchText = '';

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _organizations = [];

  bool _can(String permission) =>
      widget.isAdmin || widget.permissions.contains(permission);

  bool _isActive(Map<String, dynamic> user) => user['is_active'] != false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final usersData = await widget.apiService.getUsers();
      List<dynamic> organizationsData = [];

      // O usuário pode ter users_view sem organizations_view.
      try {
        organizationsData = await widget.apiService.getOrganizations();
      } catch (_) {
        organizationsData = [];
      }

      if (!mounted) return;
      setState(() {
        _users = usersData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _organizations = organizationsData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _name(Map<String, dynamic> user) =>
      user['name']?.toString() ?? 'Sem nome';

  String _organization(Map<String, dynamic> user) =>
      user['organization_name']?.toString() ?? 'Sem organização';

  String _role(Map<String, dynamic> user) =>
      user['role'] == 'admin' ? 'Administrador' : 'Visualizador';

  String _status(Map<String, dynamic> user) =>
      _isActive(user) ? 'Ativo' : 'Desativado';

  String _dateLabel(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) {
      return 'Não registrada';
    }
    final original = raw.toString();
    // Conserva a convenção anterior do backend: datetime sem fuso é UTC.
    final utcText = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(original)
        ? original
        : '${original}Z';
    final date = DateTime.tryParse(utcText)?.toLocal();
    if (date == null) return 'Data inválida';
    String n(int number) => number.toString().padLeft(2, '0');
    return '${n(date.day)}/${n(date.month)}/${date.year} '
        '${n(date.hour)}:${n(date.minute)}';
  }

  String _lastDeactivation(Map<String, dynamic> user) =>
      user['deactivated_at'] == null
          ? '-'
          : _dateLabel(user['deactivated_at']);

  String _reason(Map<String, dynamic> user) {
    final reason = user['deactivation_reason']?.toString().trim() ?? '';
    return reason.isEmpty ? '-' : reason;
  }

  // Pesquisa sem diferenciar maiúsculas, minúsculas ou acentos.
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãäå]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n')
        .trim();
  }

  String _userSearchText(Map<String, dynamic> user) {
    return _normalize([
      user['id']?.toString() ?? '',
      _name(user),
      user['email']?.toString() ?? '',
      _status(user),
      _role(user),
      _organization(user),
      user['organization_id']?.toString() ?? '',
      _dateLabel(user['created_at']),
      _lastDeactivation(user),
      _reason(user),
      user['created_at']?.toString() ?? '',
      user['deactivated_at']?.toString() ?? '',
    ].join(' '));
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final words = _normalize(_searchText)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return _users.where((user) {
      if (_statusFilter == 'ativos' && !_isActive(user)) return false;
      if (_statusFilter == 'desativados' && _isActive(user)) return false;
      final contents = _userSearchText(user);
      return words.every(contents.contains);
    }).toList();
  }

  // Cada valor é tratado individualmente; evita fórmulas de planilhas.
  String _csvCell(String raw) {
    var value = raw.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim();
    if (RegExp(r'^[=+\-@]').hasMatch(value)) {
      value = "'$value";
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  Future<void> _exportUsers(List<Map<String, dynamic>> users) async {
    if (users.isEmpty || _exporting || !_can('users_view')) return;
    setState(() => _exporting = true);

    try {
      final rows = <List<String>>[
        [
          'ID',
          'Nome (financeiro)',
          'E-mail',
          'Situação',
          'Cadastrado em',
          'Última desativação',
          'Último motivo',
          'Perfil',
          'Organização',
        ],
        ...users.map((user) => [
              user['id']?.toString() ?? '',
              _name(user),
              user['email']?.toString() ?? '',
              _status(user),
              _dateLabel(user['created_at']),
              _lastDeactivation(user),
              _reason(user),
              _role(user),
              _organization(user),
            ]),
      ];

      final content = rows
          .map((row) => row.map(_csvCell).join(';'))
          .join('\r\n');
      final timestamp = DateTime.now();
      String n(int value) => value.toString().padLeft(2, '0');
      final filename = 'administra_usuarios_'
          '${timestamp.year}${n(timestamp.month)}${n(timestamp.day)}_'
          '${n(timestamp.hour)}${n(timestamp.minute)}';

      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(utf8.encode('\uFEFF$content\r\n')),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      _showMessage('${users.length} registro(s) exportado(s).');
    } catch (error) {
      _showMessage('Não foi possível exportar: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openFinance(Map<String, dynamic> user) async {
    if (!_can('finance_view')) return;
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
        userName: _name(user),
      ),
    );
  }

  Future<void> _managePermissions(Map<String, dynamic> user) async {
    if (!widget.isAdmin || user['role'] == 'admin') return;
    final id = int.tryParse(user['id'].toString());
    if (id == null) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserPermissionsDialog(
        apiService: widget.apiService,
        userId: id,
        userName: _name(user),
      ),
    );
    if (mounted && saved == true) {
      _showMessage('Permissões salvas. O usuário deverá atualizar a sessão.');
    }
  }

  Future<void> _createUser() async {
    if (!_can('users_create')) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(
        organizations: _organizations,
        onSubmit: ({
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
    if (_message.isEmpty) _showMessage('Usuário cadastrado com sucesso.');
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    if (!_can('users_edit')) return;
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
        onSubmit: ({
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
    if (_message.isEmpty) _showMessage('Usuário atualizado com sucesso.');
  }

  Future<void> _deactivateUser(Map<String, dynamic> user) async {
    if (!widget.isAdmin) return;
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
                'Desativar ${_name(user)}? '
                'Os lançamentos financeiros e o histórico serão preservados.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLength: 500,
                minLines: 2,
                maxLines: 3,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Motivo da desativação *',
                  hintText: 'Exemplo: Desligamento da organização',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: controller.text.trim().length < 3
                  ? null
                  : () => Navigator.pop(dialogContext, controller.text.trim()),
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

  Future<void> _reactivateUser(Map<String, dynamic> user) async {
    if (!widget.isAdmin) return;
    final id = int.tryParse(user['id'].toString());
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reativar usuário'),
        content: Text(
          'Reativar ${_name(user)}? A conta poderá voltar a fazer login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
      if (_message.isEmpty) _showMessage('Usuário reativado com sucesso.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          SelectableText(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> user) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalhes do usuário'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailLine('Nome completo', _name(user)),
                _detailLine('E-mail', user['email']?.toString() ?? '-'),
                _detailLine('Situação', _status(user)),
                _detailLine('Perfil', _role(user)),
                _detailLine('Organização', _organization(user)),
                _detailLine('Data de cadastro', _dateLabel(user['created_at'])),
                _detailLine('Última desativação', _lastDeactivation(user)),
                _detailLine('Motivo da última desativação', _reason(user)),
                _detailLine('Identificador (ID)', user['id']?.toString() ?? '-'),
              ],
            ),
          ),
        ),
        actions: [
          if (_can('finance_view'))
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openFinance(user);
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Financeiro'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _menuLabel(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }

  Widget _userActions(Map<String, dynamic> user) {
    final active = _isActive(user);
    return PopupMenuButton<String>(
      tooltip: 'Ações de ${_name(user)}',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case 'details':
            _showDetails(user);
            break;
          case 'finance':
            _openFinance(user);
            break;
          case 'edit':
            _editUser(user);
            break;
          case 'deactivate':
            _deactivateUser(user);
            break;
          case 'reactivate':
            _reactivateUser(user);
            break;
          case 'permissions':
            _managePermissions(user);
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'details',
          child: _menuLabel(Icons.info_outline, 'Ver detalhes'),
        ),
        if (_can('finance_view'))
          PopupMenuItem(
            value: 'finance',
            child: _menuLabel(Icons.receipt_long_outlined, 'Financeiro individual'),
          ),
        if (_can('users_edit'))
          PopupMenuItem(
            value: 'edit',
            child: _menuLabel(Icons.edit_outlined, 'Editar cadastro'),
          ),
        if (widget.isAdmin)
          PopupMenuItem(
            value: active ? 'deactivate' : 'reactivate',
            child: _menuLabel(
              active
                  ? Icons.person_off_outlined
                  : Icons.person_add_alt_1_outlined,
              active ? 'Desativar usuário' : 'Reativar usuário',
            ),
          ),
        if (widget.isAdmin && user['role'] == 'viewer')
          PopupMenuItem(
            value: 'permissions',
            child: _menuLabel(Icons.admin_panel_settings_outlined, 'Gerenciar permissões'),
          ),
      ],
    );
  }

  Widget _statusBadge(Map<String, dynamic> user) {
    final active = _isActive(user);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          _status(user),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.green.shade800 : Colors.deepOrange.shade800,
          ),
        ),
      ),
    );
  }

  Widget _nameAndEmail(Map<String, dynamic> user) {
    final clickable = _can('finance_view');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: _name(user),
          child: InkWell(
            onTap: clickable ? () => _openFinance(user) : null,
            child: Text(
              _name(user),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: clickable ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                decoration: clickable ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Tooltip(
          message: user['email']?.toString() ?? '-',
          child: Text(
            user['email']?.toString() ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: AppColors.textSecondary,
    );
    return Container(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text('Usuário', style: style)),
          Expanded(flex: 2, child: Text('Situação', style: style)),
          Expanded(flex: 2, child: Text('Perfil', style: style)),
          Expanded(flex: 3, child: Text('Organização', style: style)),
          SizedBox(width: 62, child: Text('Ações', style: style)),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(flex: 4, child: _nameAndEmail(user)),
            Expanded(flex: 2, child: _statusBadge(user)),
            Expanded(
              flex: 2,
              child: Text(
                _role(user),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Tooltip(
                message: _organization(user),
                child: Text(
                  _organization(user),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: 62, child: _userActions(user)),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _nameAndEmail(user)),
              _userActions(user),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statusBadge(user),
              Text(_role(user), style: const TextStyle(fontSize: 13)),
              Text(_organization(user), style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _usersPanel(List<Map<String, dynamic>> filtered) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          return Column(
            children: [
              if (wide) _tableHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => wide
                      ? _tableRow(filtered[index])
                      : _userCard(filtered[index]),
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _filteredUsers;
    final canExport = _can('users_view') && !_loading && !_exporting &&
        _message.isEmpty && visibleUsers.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              const Text('Situação:', style: TextStyle(fontWeight: FontWeight.w600)),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'ativos', child: Text('Ativos')),
                  DropdownMenuItem(value: 'desativados', child: Text('Desativados')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _statusFilter = value);
                },
              ),
              Text(
                '${visibleUsers.length} de ${_users.length} usuário(s)',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final searchField = TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: 'Pesquisar nome, e-mail, situação, datas, motivo...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar pesquisa',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              );

              final buttons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                  const SizedBox(width: 8),
                  if (_can('users_view'))
                    OutlinedButton.icon(
                      onPressed: canExport ? () => _exportUsers(visibleUsers) : null,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Exportar CSV'),
                    ),
                  if (_can('users_create')) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _createUser,
                      icon: const Icon(Icons.add),
                      label: const Text('Novo cadastro'),
                    ),
                  ],
                ],
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: buttons,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 10),
                  buttons,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _message.isNotEmpty
                    ? Center(child: Text(_message, textAlign: TextAlign.center))
                    : visibleUsers.isEmpty
                        ? const Center(child: Text('Nenhum usuário encontrado.'))
                        : _usersPanel(visibleUsers),
          ),
        ],
      ),
    );
  }
}
