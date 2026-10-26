import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class OrganizationFormDialog extends StatefulWidget {
  final Map<String, dynamic>? organization;
  final Future<void> Function({
    required String name,
    required String type,
    required String document,
    required String address,
    required String city,
    required String state,
    required String responsibleName,
  })
  onSubmit;

  const OrganizationFormDialog({
    super.key,
    this.organization,
    required this.onSubmit,
  });

  @override
  State<OrganizationFormDialog> createState() => _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<OrganizationFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController typeController;
  late final TextEditingController documentController;
  late final TextEditingController addressController;
  late final TextEditingController cityController;
  late final TextEditingController stateController;
  late final TextEditingController responsibleNameController;

  bool loading = false;
  String message = '';

  bool get isEditing => widget.organization != null;

  @override
  void initState() {
    super.initState();

    final organization = widget.organization;

    nameController = TextEditingController(
      text: organization?['name']?.toString() ?? '',
    );
    typeController = TextEditingController(
      text: organization?['type']?.toString() ?? '',
    );
    documentController = TextEditingController(
      text: organization?['document']?.toString() ?? '',
    );
    addressController = TextEditingController(
      text: organization?['address']?.toString() ?? '',
    );
    cityController = TextEditingController(
      text: organization?['city']?.toString() ?? '',
    );
    stateController = TextEditingController(
      text: organization?['state']?.toString() ?? '',
    );
    responsibleNameController = TextEditingController(
      text: organization?['responsible_name']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    documentController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    responsibleNameController.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      await widget.onSubmit(
        name: nameController.text,
        type: typeController.text,
        document: documentController.text,
        address: addressController.text,
        city: cityController.text,
        state: stateController.text,
        responsibleName: responsibleNameController.text,
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

  Widget field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: requiredField,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                          Icons.apartment,
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
                                  ? 'Editar organização'
                                  : 'Nova organização',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Preencha os dados administrativos da organização.',
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
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: 'Nome da organização',
                          controller: nameController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: field(label: 'Tipo', controller: typeController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: 'Documento',
                          controller: documentController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: field(
                          label: 'Responsável',
                          controller: responsibleNameController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  field(label: 'Endereço', controller: addressController),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: 'Cidade',
                          controller: cityController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 140,
                        child: field(
                          label: 'Estado',
                          controller: stateController,
                        ),
                      ),
                    ],
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
