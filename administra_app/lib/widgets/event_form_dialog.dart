import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';

class EventFormDialog extends StatefulWidget {
  final Map<String, dynamic>? event;
  final List<dynamic> organizations;
  final Future<void> Function({
    required String title,
    required String description,
    required String date,
    required String location,
    required int organizationId,
  }) onSubmit;

  const EventFormDialog({
    super.key,
    this.event,
    required this.organizations,
    required this.onSubmit,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController dateController;
  late final TextEditingController locationController;

  int? selectedOrganizationId;
  bool loading = false;
  String message = '';

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    titleController = TextEditingController(
      text: event?['title']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: event?['description']?.toString() ?? '',
    );

    dateController = TextEditingController(
      text: event?['date']?.toString() ?? '',
    );

    locationController = TextEditingController(
      text: event?['location']?.toString() ?? '',
    );

    final organizationValue = event?['organization_id'];

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
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    locationController.dispose();
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

    if (selectedOrganizationId == null) {
      setState(() {
        message = 'Selecione uma organização.';
      });
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      await widget.onSubmit(
        title: titleController.text,
        description: descriptionController.text,
        date: dateController.text,
        location: locationController.text,
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

  Widget field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: requiredField,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        width: 760,
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
                          Icons.event_note,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Editar evento' : 'Novo evento',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Preencha os dados do evento e vincule a uma organização.',
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
                  field(
                    label: 'Título do evento',
                    controller: titleController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: 'Data e hora',
                          controller: dateController,
                          helperText: 'Exemplo: 2026-08-30T19:00:00',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: field(
                          label: 'Local',
                          controller: locationController,
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
                  const SizedBox(height: 16),
                  field(
                    label: 'Descrição',
                    controller: descriptionController,
                    maxLines: 3,
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