import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectPage;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectPage,
    required this.onLogout,
  });

  Widget _menuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      selectedColor: AppColors.primary,
      onTap: () => onSelectPage(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.business_center, color: Colors.white, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'Administra+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Painel administrativo',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          _menuItem(icon: Icons.dashboard, title: 'Dashboard', index: 0),
          _menuItem(icon: Icons.apartment, title: 'Organizações', index: 1),
          _menuItem(icon: Icons.event, title: 'Eventos', index: 2),
          _menuItem(icon: Icons.receipt_long, title: 'Financeiro', index: 3),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
