import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/list_page_layout.dart';

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

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ListPageLayout(
      title: 'Eventos cadastrados',
      subtitle: 'Consulta dos eventos registrados no sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhum evento cadastrado.',
      onRefresh: loadEvents,
      children: events.map((item) {
        return InfoCard(
          icon: Icons.event,
          title: texto(item['title']),
          subtitle: 'Local: ${texto(item['location'])}',
          rows: [
            InfoRow(label: 'ID', value: texto(item['id'])),
            InfoRow(label: 'Descrição', value: texto(item['description'])),
            InfoRow(label: 'Data', value: formatarData(item['date'])),
            InfoRow(
              label: 'Organização',
              value: texto(
                item['organization_name'] ?? item['organization_id'],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}