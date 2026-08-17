import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';
import '../services/api_service.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends StatefulWidget {
  final ApiService apiService;

  const DashboardPage({
    super.key,
    required this.apiService,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  String message = '';
  Map<String, dynamic>? dashboard;

  Future<void> loadDashboard() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final data = await widget.apiService.getDashboard();

      setState(() {
        dashboard = data;
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao carregar dashboard.';
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
    loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final totals = dashboard?['totais'];
    final finance = dashboard?['financeiro'];

    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : message.isNotEmpty
                ? Center(
                    child: Text(
                      message,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo geral do sistema',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Informações consolidadas do backend Administra+.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SummaryCard(
                              title: 'Organizações',
                              value: '${totals?['organizacoes'] ?? 0}',
                              icon: Icons.apartment,
                            ),
                            SummaryCard(
                              title: 'Usuários',
                              value: '${totals?['usuarios'] ?? 0}',
                              icon: Icons.people,
                            ),
                            SummaryCard(
                              title: 'Eventos',
                              value: '${totals?['eventos'] ?? 0}',
                              icon: Icons.event,
                            ),
                            SummaryCard(
                              title: 'Confirmações',
                              value: '${totals?['confirmacoes'] ?? 0}',
                              icon: Icons.check_circle,
                            ),
                            SummaryCard(
                              title: 'Lançamentos',
                              value:
                                  '${totals?['lancamentos_financeiros'] ?? 0}',
                              icon: Icons.receipt_long,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Resumo financeiro',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SummaryCard(
                              title: 'Entradas',
                              value: formatarValor(
                                finance?['total_entradas'] ?? 0,
                              ),
                              icon: Icons.arrow_downward,
                            ),
                            SummaryCard(
                              title: 'Saídas',
                              value: formatarValor(
                                finance?['total_saidas'] ?? 0,
                              ),
                              icon: Icons.arrow_upward,
                            ),
                            SummaryCard(
                              title: 'Saldo final',
                              value: formatarValor(
                                finance?['saldo_final'] ?? 0,
                              ),
                              icon: Icons.account_balance_wallet,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}