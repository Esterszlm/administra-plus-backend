import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AdminTablePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool loading;
  final String message;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNew;
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
    required this.columns,
    required this.rows,
    this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: loading ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
            if (onNew != null) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: loading ? null : onNew,
                icon: const Icon(Icons.add),
                label: const Text('Novo cadastro'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        if (loading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (message.isNotEmpty)
          Expanded(
            child: Center(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else if (rows.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.primaryLight,
                      ),
                      columnSpacing: 28,
                      horizontalMargin: 22,
                      columns: columns,
                      rows: rows,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}