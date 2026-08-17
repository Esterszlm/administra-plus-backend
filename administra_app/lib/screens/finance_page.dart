import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/list_page_layout.dart';

class FinancePage extends StatefulWidget {
  final ApiService apiService;

  const FinancePage({
    super.key,
    required this.apiService,
  });

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool loading = true;
  String message = '';
  List<dynamic> finances = [];

  Future<void> loadFinances() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final data = await widget.apiService.getFinance();

      setState(() {
        finances = data;
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao carregar financeiro.';
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
    loadFinances();
  }

  @override
  Widget build(BuildContext context) {
    return ListPageLayout(
      title: 'Lançamentos financeiros',
      subtitle: 'Consulta das entradas e saídas registradas no sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhum lançamento financeiro cadastrado.',
      onRefresh: loadFinances,
      children: finances.map((item) {
        return InfoCard(
          icon: Icons.receipt_long,
          title: texto(item['description']),
          subtitle: 'Valor: ${formatarValor(item['amount'])}',
          rows: [
            InfoRow(label: 'ID', value: texto(item['id'])),
            InfoRow(label: 'Tipo', value: texto(item['type'])),
            InfoRow(label: 'Valor', value: formatarValor(item['amount'])),
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