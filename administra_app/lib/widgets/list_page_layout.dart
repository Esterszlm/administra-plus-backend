import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ListPageLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool loading;
  final String message;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final List<Widget> children;

  const ListPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.message,
    required this.emptyMessage,
    required this.onRefresh,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Atualizar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (children.isEmpty)
                          Text(
                            emptyMessage,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: children,
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}