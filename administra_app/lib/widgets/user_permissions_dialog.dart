import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// O administrador escolhe permissões de leitura e escrita por módulo.
/// Os valores são persistidos em UserPermission, não apenas no navegador.
class UserPermissionsDialog extends StatefulWidget {
  final ApiService apiService;
  final int userId;
  final String userName;

  const UserPermissionsDialog({
    super.key,
    required this.apiService,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserPermissionsDialog> createState() => _UserPermissionsDialogState();
}

class _UserPermissionsDialogState extends State<UserPermissionsDialog> {
  static const Map<String, String> _moduleLabels = {
    'dashboard': 'Dashboard',
    'organizations': 'Organizações',
    'events': 'Eventos',
    'finance': 'Financeiro',
    'users': 'Usuários',
  };

  static const Map<String, String> _actionLabels = {
    'view': 'Visualizar',
    'create': 'Cadastrar',
    'edit': 'Editar',
    'delete': 'Excluir',
  };

  bool _loading = true;
  bool _saving = false;
  String _error = '';
  Set<String> _selected = <String>{};
  Map<String, List<String>> _groups = {};
  List<String> _missing = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final catalog = await widget.apiService.getPermissionCatalog();
      final assignments = await widget.apiService.getUserPermissionAssignments(
        widget.userId,
      );
      final groups = <String, List<String>>{};
      final rawGroups = catalog['groups'];
      if (rawGroups is Map) {
        for (final entry in rawGroups.entries) {
          if (entry.value is List) {
            groups[entry.key.toString()] = (entry.value as List)
                .map((value) => value.toString())
                .toList();
          }
        }
      }
      final managed = groups.values.expand((items) => items).toSet();
      final selected = <String>{};
      for (final record in assignments) {
        if (record is Map && record['permission_name'] != null) {
          final name = record['permission_name'].toString();
          if (managed.contains(name)) selected.add(name);
        }
      }
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _selected = selected;
        _missing = (catalog['missing'] as List? ?? [])
            .map((value) => value.toString())
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(String permission, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(permission);
        final module = permission.split('_').first;
        if (!permission.endsWith('_view')) {
          _selected.add('${module}_view');
        }
        // Os formulários de cadastro usam a lista de organizações.
        if (permission == 'finance_create' ||
            permission == 'events_create' ||
            permission == 'users_create') {
          _selected.add('organizations_view');
        }
      } else {
        _selected.remove(permission);
        if (permission.endsWith('_view')) {
          final module = permission.split('_').first;
          _selected.removeWhere((name) => name.startsWith('${module}_'));
          if (module == 'organizations') {
            _selected.remove('finance_create');
            _selected.remove('events_create');
            _selected.remove('users_create');
          }
        }
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _missing.isNotEmpty) return;
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await widget.apiService.setUserPermissions(widget.userId, _selected);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, size: 29),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Permissões — ${widget.userName}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Marque o que esta pessoa pode visualizar e fazer. '
                'Desmarcar Visualizar remove também as ações do módulo.',
              ),
              if (_missing.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Permissões ausentes no banco: ${_missing.join(', ')}. '
                  'Execute migrar_catalogo_permissoes.py.',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_error, style: const TextStyle(color: Colors.red)),
              ],
              const Divider(height: 24),
              Flexible(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        shrinkWrap: true,
                        children: _moduleLabels.entries.map((module) {
                          final rights = _groups[module.key] ?? <String>[];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.value,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 0,
                                    children: rights.map((name) {
                                      final action = name.substring(
                                        module.key.length + 1,
                                      );
                                      return SizedBox(
                                        width: 140,
                                        child: CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          title: Text(
                                            _actionLabels[action] ?? action,
                                          ),
                                          value: _selected.contains(name),
                                          onChanged:
                                              _saving || _missing.isNotEmpty
                                              ? null
                                              : (checked) => _toggle(
                                                  name,
                                                  checked ?? false,
                                                ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loading || _saving || _missing.isNotEmpty
                        ? null
                        : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Salvando...' : 'Salvar permissões'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
