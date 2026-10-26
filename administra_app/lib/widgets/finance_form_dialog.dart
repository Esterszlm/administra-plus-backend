import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';

class FinanceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? finance;
  final List<dynamic> organizations;
  final List<dynamic> users;
  final Future<void> Function({
    required String type,
    required double amount,
    required String description,
    required int organizationId,
    int? userId,
  })
  onSubmit;

  const FinanceFormDialog({
    super.key,
    this.finance,
    required this.organizations,
    required this.users,
    required this.onSubmit,
  });

  @override
  State<FinanceFormDialog> createState() => _FinanceFormDialogState();
}

class _FinanceFormDialogState extends State<FinanceFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController descriptionController;
  late final TextEditingController amountController;

  String selectedType = 'entrada';
  int? selectedOrganizationId;
  int selectedUserId = -1;
  bool loading = false;
  String message = '';

  bool get isEditing => widget.finance != null;

  int? _intValue(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  List<Map<String, dynamic>> get eligibleUsers {
    return widget.users
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where(
          (user) =>
              selectedOrganizationId != null &&
              _intValue(user['organization_id']) == selectedOrganizationId &&
              (user['is_active'] != false ||
                  _intValue(user['id']) == selectedUserId),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();

    final finance = widget.finance;
    descriptionController = TextEditingController(
      text: finance?['description']?.toString() ?? '',
    );
    amountController = TextEditingController(
      text: finance?['amount']?.toString() ?? '',
    );

    final typeValue = finance?['type']?.toString();
    if (typeValue == 'entrada' || typeValue == 'saida') {
      selectedType = typeValue!;
    }

    selectedOrganizationId = _intValue(finance?['organization_id']);
    if (selectedOrganizationId == null && widget.organizations.isNotEmpty) {
      selectedOrganizationId = _intValue(widget.organizations.first['id']);
    }

    final existingUserId = _intValue(finance?['user_id']);
    if (existingUserId != null) {
      // Preserva o vínculo existente, mesmo quando a conta não tem permissão
      // para consultar a lista completa de usuários.
      selectedUserId = existingUserId;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final amount = double.tryParse(value.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite) return 'Informe um valor válido';
    if (amount <= 0) return 'O valor deve ser maior que zero';
    return null;
  }

  Future<void> submit() async {
    if (loading || !formKey.currentState!.validate()) return;

    if (selectedOrganizationId == null) {
      setState(() => message = 'Selecione uma organização.');
      return;
    }

    final amount = double.parse(
      amountController.text.trim().replaceAll(',', '.'),
    );

    setState(() {
      loading = true;
      message = '';
    });

    try {
      await widget.onSubmit(
        type: selectedType,
        amount: amount,
        description: descriptionController.text,
        organizationId: selectedOrganizationId!,
        userId: selectedUserId == -1 ? null : selectedUserId,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableUsers = eligibleUsers;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Editar lançamento financeiro'
                                  : 'Novo lançamento financeiro',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Registre entradas e saídas por organização e, opcionalmente, por usuário.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: descriptionController,
                    validator: requiredField,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const [
                            DropdownMenuItem(
                              value: 'entrada',
                              child: Text('Entrada'),
                            ),
                            DropdownMenuItem(
                              value: 'saida',
                              child: Text('Saída'),
                            ),
                          ],
                          onChanged: loading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => selectedType = value);
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          validator: amountValidator,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Valor',
                            helperText: 'Exemplo: 150,75',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedOrganizationId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Organização'),
                    items: widget.organizations.map((organization) {
                      return DropdownMenuItem<int>(
                        value: _intValue(organization['id']),
                        child: Text(
                          texto(organization['name']),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              selectedOrganizationId = value;
                              // O usuário anterior não pode permanecer ligado
                              // a um lançamento de outra organização.
                              selectedUserId = -1;
                            });
                          },
                    validator: (value) =>
                        value == null ? 'Selecione uma organização' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey('finance-user-$selectedOrganizationId'),
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Usuário vinculado (opcional)',
                      helperText: 'Somente usuários da organização escolhida',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: -1,
                        child: Text('Sem usuário vinculado'),
                      ),
                      if (selectedUserId != -1 &&
                          !availableUsers.any(
                            (user) => _intValue(user['id']) == selectedUserId,
                          ))
                        DropdownMenuItem<int>(
                          value: selectedUserId,
                          child: Text(
                            'Usuário #$selectedUserId (vínculo atual)',
                          ),
                        ),
                      ...availableUsers.map(
                        (user) => DropdownMenuItem<int>(
                          value: _intValue(user['id']),
                          child: Text(
                            user['is_active'] == false
                                ? '${texto(user['name'])} (desativado - vínculo anterior)'
                                : texto(user['name']),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: loading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => selectedUserId = value);
                          },
                  ),
                  if (availableUsers.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Não há usuários disponíveis para vínculo nesta organização, ou sua conta não tem permissão para listá-los.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: loading ? null : submit,
                        icon: loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isEditing ? 'Salvar alterações' : 'Cadastrar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
