import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';

class EventsPage extends StatefulWidget {
  final ApiService apiService;

  const EventsPage({
    super.key,
    required this.apiService,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool loading = true;
  String message = '';
  List<dynamic> events = [];

  Future<void> loadEvents() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final data = await widget.apiService.getEvents();

      setState(() {
        events = data;
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

  void showActionMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return AdminTablePage(
      title: 'Eventos',
      subtitle: 'Gestão dos eventos cadastrados no sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhum evento cadastrado.',
      onRefresh: loadEvents,
      onNew: () => showActionMessage(
        'Cadastro de evento será criado na próxima etapa.',
      ),
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
              Text(
                texto(item['organization_name'] ?? item['organization_id']),
              ),
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
                    onPressed: () => showActionMessage(
                      'Edição de evento será criada na próxima etapa.',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => showActionMessage(
                      'Exclusão de evento será criada na próxima etapa.',
                    ),
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