import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> organizations;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required String role,
    int? organizationId,
  }) onSubmit;

  const UserFormDialog({
    super.key,
    this.user,
    required this.organizations,
    required this.onSubmit,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  String _role = 'viewer';
  int _organizationId = -1;
  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _nameController = TextEditingController(
      text: user?['name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: user?['email']?.toString() ?? '',
    );
    _passwordController = TextEditingController();

    if (user?['role'] == 'admin') {
      _role = 'admin';
    }

    final storedOrganizationId = int.tryParse(
      user?['organization_id']?.toString() ?? '',
    );

    if (storedOrganizationId != null &&
        widget.organizations.any(
          (organization) => organization['id'] == storedOrganizationId,
        )) {
      _organizationId = storedOrganizationId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 8) {
      return 'Use pelo menos 8 caracteres';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await widget.onSubmit(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _isEditing ? '' : _passwordController.text,
        role: _role,
        organizationId: _organizationId == -1 ? null : _organizationId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.manage_accounts_outlined,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar usuário' : 'Novo usuário',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  validator: _validateRequired,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                  ),
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Senha de acesso',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Perfil do usuário',
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'viewer',
                      child: Text('Visualizador'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'admin',
                      child: Text('Administrador'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _role = value);
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _organizationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Organização',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text('Sem organização vinculada'),
                    ),
                    ...widget.organizations.map((organization) {
                      return DropdownMenuItem<int>(
                        value: organization['id'] as int,
                        child: Text(
                          organization['name'].toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _organizationId = value);
                        },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'A senha não é alterada nesta tela.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isEditing ? 'Salvar alterações' : 'Cadastrar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
