import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AdminTablePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool loading;
  final String message;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final VoidCallback onNew;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const AdminTablePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.message,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onNew,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : message.isNotEmpty
                ? Center(
                    child: Text(
                      message,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Atualizar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: onNew,
                              icon: const Icon(Icons.add),
                              label: const Text('Novo cadastro'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: rows.isEmpty
                              ? Center(
                                  child: Text(
                                    emptyMessage,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                          AppColors.surfaceSoft,
                                        ),
                                        headingTextStyle: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        dataTextStyle: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        columnSpacing: 34,
                                        horizontalMargin: 24,
                                        columns: columns,
                                        rows: rows,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}