import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import 'dashboard_page.dart';
import 'events_page.dart';
import 'finance_page.dart';
import 'login_page.dart';
import 'organizations_page.dart';

class HomePage extends StatefulWidget {
  final String token;
  final String baseUrl;

  const HomePage({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;

  final List<String> titles = [
    'Dashboard',
    'Organizações',
    'Eventos',
    'Financeiro',
  ];

  ApiService get apiService {
    return ApiService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    );
  }

  void selectPage(int index) {
    setState(() {
      selectedPage = index;
    });
  }

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Widget currentPage() {
    if (selectedPage == 0) {
      return DashboardPage(apiService: apiService);
    }

    if (selectedPage == 1) {
      return OrganizationsPage(apiService: apiService);
    }

    if (selectedPage == 2) {
      return EventsPage(apiService: apiService);
    }

    return FinancePage(apiService: apiService);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: selectedPage,
      title: titles[selectedPage],
      onSelectPage: selectPage,
      onLogout: logout,
      child: currentPage(),
    );
  }
}