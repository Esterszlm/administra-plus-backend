import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import 'dashboard_page.dart';
import 'events_page.dart';
import 'finance_page.dart';
import 'login_page.dart';
import 'organizations_page.dart';
import 'users_page.dart';

class HomePage extends StatefulWidget {
  final String token;
  final String baseUrl;

  const HomePage({super.key, required this.token, required this.baseUrl});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;

  Map<String, dynamic>? _currentUser;
  bool _checkingApi = false;
  bool _apiVerified = false;
  String _apiStatus = 'Verificação pendente';

  @override
  void initState() {
    super.initState();
    _verifySession();
  }

  // A própria API confirma quem está autenticado. Não usamos
  // nome ou e-mail fixos na interface.
  Future<void> _verifySession() async {
    if (_checkingApi) return;

    setState(() {
      _checkingApi = true;
      _apiStatus = 'Verificando API';
    });

    try {
      final base = widget.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final response = await http
          .get(
            Uri.parse('$base/me'),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Resposta inválida de /me');
        }

        setState(() {
          _currentUser = decoded;
          _apiVerified = true;
          _apiStatus = 'API verificada';
        });
      } else {
        setState(() {
          _currentUser = null;
          _apiVerified = false;
          _apiStatus = response.statusCode == 401
              ? 'Sessão inválida'
              : 'Erro HTTP ${response.statusCode}';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _apiVerified = false;
        _apiStatus = 'Sem conexão';
      });
    } finally {
      if (mounted) {
        setState(() => _checkingApi = false);
      }
    }
  }

  String get _userName {
    final name = _currentUser?['name']?.toString().trim();
    return name == null || name.isEmpty ? 'Usuário não verificado' : name;
  }

  String get _userEmail {
    final email = _currentUser?['email']?.toString().trim();
    return email == null || email.isEmpty ? '-' : email;
  }

  String get _userRole {
    switch (_currentUser?['role']?.toString()) {
      case 'admin':
        return 'Administrador';
      case 'viewer':
        return 'Visualizador';
      default:
        return 'Perfil não verificado';
    }
  }

  final List<String> titles = [
    'Dashboard',
    'Organizações',
    'Eventos',
    'Financeiro',
    'Usuários',
  ];

  ApiService get apiService {
    return ApiService(baseUrl: widget.baseUrl, token: widget.token);
  }

  void selectPage(int index) {
    if (index < 0 || index >= titles.length) return;

    setState(() {
      selectedPage = index;
    });
  }

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
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

    if (selectedPage == 3) {
      return FinancePage(apiService: apiService);
    }

    return UsersPage(apiService: apiService);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: selectedPage,
      title: titles[selectedPage],
      onSelectPage: selectPage,
      onLogout: logout,
      userName: _userName,
      userEmail: _userEmail,
      userRole: _userRole,
      apiStatus: _apiStatus,
      apiVerified: _apiVerified,
      checkingApi: _checkingApi,
      onRefreshApi: _verifySession,
      child: currentPage(),
    );
  }
}
