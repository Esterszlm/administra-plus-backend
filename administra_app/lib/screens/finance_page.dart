import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/admin_table_page.dart';

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

  void showActionMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String tipoFormatado(dynamic valor) {
    final tipo = texto(valor);

    if (tipo == 'entrada') {
      return 'Entrada';
    }

    if (tipo == 'saida') {
      return 'Saída';
    }

    return tipo;
  }

  @override
  void initState() {
    super.initState();
    loadFinances();
  }

  @override
  Widget build(BuildContext context) {
    return AdminTablePage(
      title: 'Financeiro',
      subtitle: 'Gestão dos lançamentos financeiros do sistema.',
      loading: loading,
      message: message,
      emptyMessage: 'Nenhum lançamento financeiro cadastrado.',
      onRefresh: loadFinances,
      onNew: () => showActionMessage(
        'Cadastro financeiro será criado na próxima etapa.',
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Descrição')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Valor')),
        DataColumn(label: Text('Organização')),
        DataColumn(label: Text('Ações')),
      ],
      rows: finances.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(texto(item['id']))),
            DataCell(Text(texto(item['description']))),
            DataCell(Text(tipoFormatado(item['type']))),
            DataCell(Text(formatarValor(item['amount']))),
            DataCell(
              Text(
                texto(item['organization_name'] ?? item['organization_id']),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit),
                    onPressed: () => showActionMessage(
                      'Edição financeira será criada na próxima etapa.',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => showActionMessage(
                      'Exclusão financeira será criada na próxima etapa.',
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