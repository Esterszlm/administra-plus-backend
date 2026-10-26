import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';

class UserFinanceDialog extends StatefulWidget {
  final ApiService apiService;
  final int userId;
  final String userName;

  const UserFinanceDialog({
    super.key,
    required this.apiService,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserFinanceDialog> createState() => _UserFinanceDialogState();
}

class _UserFinanceDialogState extends State<UserFinanceDialog> {
  late Future<Map<String, dynamic>> _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.apiService.getUserFinanceSummary(widget.userId);
  }

  void _refresh() {
    setState(() {
      _summary = widget.apiService.getUserFinanceSummary(widget.userId);
    });
  }

  String _date(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '-';
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
        '${two(parsed.hour)}:${two(parsed.minute)}';
  }

  Widget _totalCard(String title, dynamic amount, Color color) {
    return Container(
      width: 206,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatarValor(amount),
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Map<String, dynamic> data) {
    final entries = (data['lancamentos'] is List)
        ? (data['lancamentos'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _totalCard(
                'Total de entradas',
                data['total_entradas'],
                AppColors.success,
              ),
              _totalCard(
                'Total de saídas',
                data['total_saidas'],
                AppColors.danger,
              ),
              _totalCard('Saldo individual', data['saldo'], AppColors.primary),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Histórico financeiro (${data['quantidade_lancamentos'] ?? entries.length})',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Nenhum lançamento vinculado a este usuário.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Descrição')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Valor')),
                  DataColumn(label: Text('Organização')),
                ],
                rows: entries.map((entry) {
                  final isIncome = entry['type'] == 'entrada';
                  return DataRow(
                    cells: [
                      DataCell(Text(_date(entry['date']))),
                      DataCell(Text(entry['description']?.toString() ?? '-')),
                      DataCell(Text(isIncome ? 'Entrada' : 'Saída')),
                      DataCell(
                        Text(
                          formatarValor(entry['amount']),
                          style: TextStyle(
                            color: isIncome
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(entry['organization_name']?.toString() ?? '-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 770,
        height: MediaQuery.of(context).size.height * 0.77,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financeiro individual',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar resumo',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 28),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _summary,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              snapshot.error.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      );
                    }
                    return _content(snapshot.data ?? <String, dynamic>{});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
