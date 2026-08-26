import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';

class FinanceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? finance;
  final List<dynamic> organizations;
  final Future<void> Function({
    required String type,
    required double amount,
    required String description,
    required int organizationId,
  }) onSubmit;

  const FinanceFormDialog({
    super.key,
    this.finance,
    required this.organizations,
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

  bool loading = false;
  String message = '';

  bool get isEditing => widget.finance != null;

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

    final organizationValue = finance?['organization_id'];

    if (organizationValue != null) {
      selectedOrganizationId = int.tryParse(organizationValue.toString());
    } else if (widget.organizations.isNotEmpty) {
      selectedOrganizationId = int.tryParse(
        widget.organizations.first['id'].toString(),
      );
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  String? amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    final normalized = value.replaceAll(',', '.');
    final amount = double.tryParse(normalized);

    if (amount == null) {
      return 'Informe um valor válido';
    }

    if (amount <= 0) {
      return 'O valor deve ser maior que zero';
    }

    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedOrganizationId == null) {
      setState(() {
        message = 'Selecione uma organização.';
      });
      return;
    }

    final amount = double.parse(
      amountController.text.replaceAll(',', '.'),
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
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        message = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        width: 720,
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
                              'Registre entradas e saídas vinculadas a uma organização.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: loading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: descriptionController,
                    validator: requiredField,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                          ),
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

                                  setState(() {
                                    selectedType = value;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          validator: amountValidator,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Valor',
                            helperText: 'Exemplo: 150.75',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedOrganizationId,
                    decoration: const InputDecoration(
                      labelText: 'Organização',
                    ),
                    items: widget.organizations.map((organization) {
                      final id = int.tryParse(organization['id'].toString());

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(texto(organization['name'])),
                      );
                    }).toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              selectedOrganizationId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma organização';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (message.isNotEmpty)
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: loading ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: loading ? null : submit,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
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