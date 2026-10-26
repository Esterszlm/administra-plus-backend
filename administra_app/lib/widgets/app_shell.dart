import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppShell extends StatelessWidget {
  final int selectedIndex;
  final Set<int> allowedPages;
  final String title;
  final Widget child;
  final Function(int) onSelectPage;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final String userRole;
  final String apiStatus;
  final bool apiVerified;
  final bool checkingApi;
  final VoidCallback onRefreshApi;

  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.allowedPages,
    required this.title,
    required this.child,
    required this.onSelectPage,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.apiStatus,
    required this.apiVerified,
    required this.checkingApi,
    required this.onRefreshApi,
  });

  Widget _menuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool selected = selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelectPage(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administra+',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gestão administrativa',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (allowedPages.contains(0))
            _menuItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              index: 0,
            ),
          if (allowedPages.contains(1))
            _menuItem(
              icon: Icons.apartment_outlined,
              title: 'Organizações',
              index: 1,
            ),
          if (allowedPages.contains(2))
            _menuItem(
              icon: Icons.event_note_outlined,
              title: 'Eventos',
              index: 2,
            ),
          if (allowedPages.contains(3))
            _menuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Financeiro',
              index: 3,
            ),
          if (allowedPages.contains(4))
            _menuItem(icon: Icons.people_outline, title: 'Usuários', index: 4),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onLogout,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: AppColors.danger, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Sair do sistema',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topbar() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Versão acadêmica',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: checkingApi
                ? 'Verificando a API...'
                : 'Clique para verificar novamente a API e sua sessão',
            child: InkWell(
              onTap: checkingApi ? null : onRefreshApi,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (checkingApi)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: apiVerified
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      apiStatus,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.refresh,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _sidebar(),
          Expanded(
            child: Column(
              children: [
                _topbar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
