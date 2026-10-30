import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/event_form_dialog.dart';

class EventsPage extends StatefulWidget {
  final ApiService apiService;

  const EventsPage({super.key, required this.apiService});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool loading = true;
  String message = '';
  List<dynamic> events = [];
  List<dynamic> organizations = [];

  Future<void> loadData() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
       final eventsData = await widget.apiService.getEvents();
      List<dynamic> organizationsData = [];
      try {
        organizationsData = await widget.apiService.getOrganizations();
      } catch (_) {
        // Sem permissão de organizações: a tela continua exibindo os eventos.
      }

      setState(() {
        events = eventsData;
        organizations = organizationsData;
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao carregar eventos.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return EventFormDialog(
          organizations: organizations,
          onSubmit:
              ({
                required String title,
                required String description,
                required String date,
                required String location,
                required int organizationId,
              }) async {
                await widget.apiService.createEvent(
                  title: title,
                  description: description,
                  date: date,
                  location: location,
                  organizationId: organizationId,
                );
              },
        );
      },
    );

    if (result == true) {
      showSuccess('Evento cadastrado com sucesso.');
      await loadData();
    }
  }

  Future<void> openEditDialog(Map<String, dynamic> event) async {
    final id = int.tryParse(event['id'].toString());

    if (id == null) {
      showSuccess('ID do evento inválido.');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return EventFormDialog(
          event: event,
          organizations: organizations,
          onSubmit:
              ({
                required String title,
                required String description,
                required String date,
                required String location,
                required int organizationId,
              }) async {
                await widget.apiService.updateEvent(
                  id: id,
                  title: title,
                  description: description,
                  date: date,
                  location: location,
                  organizationId: organizationId,
                );
              },
        );
      },
    );

    if (result == true) {
      showSuccess('Evento atualizado com sucesso.');
      await loadData();
    }
  }

  Future<void> confirmDelete(Map<String, dynamic> event) async {
    final id = int.tryParse(event['id'].toString());

    if (id == null) {
      showSuccess('ID do evento inválido.');
      return;
    }

    final title = texto(event['title']);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir evento'),
          content: Text('Tem certeza que deseja excluir o evento "$title"?'),
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
        await widget.apiService.deleteEvent(id);
        showSuccess('Evento excluído com sucesso.');
        await loadData();
      } catch (e) {
        showSuccess(e.toString().replaceAll('Exception: ', ''));
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
      title: 'Eventos',
      subtitle: 'Gestão dos eventos cadastrados no sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhum evento cadastrado.',
      onRefresh: loadData,
      onNew: openCreateDialog,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Título')),
        DataColumn(label: Text('Local')),
        DataColumn(label: Text('Data')),
        DataColumn(label: Text('Organização')),
        DataColumn(label: Text('Descrição')),
        DataColumn(label: Text('Ações')),
      ],
      rows: events.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(texto(item['id']))),
            DataCell(Text(texto(item['title']))),
            DataCell(Text(texto(item['location']))),
            DataCell(Text(formatarData(item['date']))),
            DataCell(
              Text(texto(item['organization_name'] ?? item['organization_id'])),
            ),
            DataCell(
              SizedBox(
                width: 260,
                child: Text(
                  texto(item['description']),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      openEditDialog(Map<String, dynamic>.from(item));
                    },
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      confirmDelete(Map<String, dynamic>.from(item));
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
