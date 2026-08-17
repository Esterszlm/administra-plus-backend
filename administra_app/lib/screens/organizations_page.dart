import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/list_page_layout.dart';

class OrganizationsPage extends StatefulWidget {
  final ApiService apiService;

  const OrganizationsPage({
    super.key,
    required this.apiService,
  });

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  bool loading = true;
  String message = '';
  List<dynamic> organizations = [];

  Future<void> loadOrganizations() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final data = await widget.apiService.getOrganizations();

      setState(() {
        organizations = data;
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao carregar organizações.';
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
    loadOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    return ListPageLayout(
      title: 'Organizações cadastradas',
      subtitle: 'Consulta das organizações registradas no sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhuma organização cadastrada.',
      onRefresh: loadOrganizations,
      children: organizations.map((item) {
        return InfoCard(
          icon: Icons.apartment,
          title: texto(item['name']),
          subtitle: 'Documento: ${texto(item['document'])}',
          rows: [
            InfoRow(label: 'ID', value: texto(item['id'])),
            InfoRow(label: 'Tipo', value: texto(item['type'])),
            InfoRow(label: 'Cidade', value: texto(item['city'])),
            InfoRow(label: 'Estado', value: texto(item['state'])),
            InfoRow(
              label: 'Responsável',
              value: texto(item['responsible_name']),
            ),
          ],
        );
      }).toList(),
    );
  }
}