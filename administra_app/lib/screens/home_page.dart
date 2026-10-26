import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/access_scope.dart';
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
  bool _permissionsLoaded = false;
  Set<String> _permissions = <String>{};
  Set<int> _allowedPages = <int>{};

  @override
  void initState() {
    super.initState();
    _verifySession();
  }

  // Valida a identidade e carrega as permissões efetivas do servidor.
  // Enquanto não obtivermos as permissões, nenhuma página é carregada.
  Future<void> _verifySession() async {
    if (_checkingApi) return;
    setState(() {
      _checkingApi = true;
      _permissionsLoaded = false;
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

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _apiVerified = false;
          _currentUser = null;
          _allowedPages = <int>{};
          _apiStatus = response.statusCode == 401
              ? 'Sessão inválida'
              : 'Erro HTTP ${response.statusCode}';
        });
        return;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Resposta inválida de /me');
      }

      final access = await apiService.getMyPermissions();
      final raw = access['permissions'];
      if (raw is! List) {
        throw const FormatException('Resposta inválida de /permissions/me');
      }
      final permissions = raw.map((item) => item.toString()).toSet();
      final isAdmin = decoded['role'] == 'admin';
      final allowed = <int>{};
      const modules = [
        'dashboard',
        'organizations',
        'events',
        'finance',
        'users',
      ];
      for (var index = 0; index < modules.length; index++) {
        if (isAdmin || permissions.contains('${modules[index]}_view')) {
          allowed.add(index);
        }
      }
      if (!mounted) return;
      setState(() {
        _currentUser = decoded;
        _permissions = permissions;
        _allowedPages = allowed;
        _permissionsLoaded = true;
        _apiVerified = true;
        _apiStatus = 'API verificada';
        if (!allowed.contains(selectedPage)) {
          selectedPage = allowed.isEmpty ? -1 : allowed.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiVerified = false;
        _permissionsLoaded = false;
        _permissions = <String>{};
        _allowedPages = <int>{};
        _apiStatus = 'Falha ao verificar acesso';
      });
    } finally {
      if (mounted) setState(() => _checkingApi = false);
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
    if (index < 0 || index >= titles.length || !_allowedPages.contains(index)) {
      return;
    }

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
    if (_checkingApi || !_permissionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allowedPages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Seu usuário ainda não possui módulos liberados. '
            'Peça ao administrador para configurar suas permissões.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!_allowedPages.contains(selectedPage)) {
      return const Center(child: Text('Acesso não autorizado.'));
    }
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
      return FinancePage(
        apiService: apiService,
        isAdmin: _currentUser?['role'] == 'admin',
        permissions: _permissions,
      );
    }

    return UsersPage(
      apiService: apiService,
      isAdmin: _currentUser?['role'] == 'admin',
      permissions: _permissions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: selectedPage,
      title: selectedPage < 0 ? 'Acesso restrito' : titles[selectedPage],
      allowedPages: _allowedPages,
      onSelectPage: selectPage,
      onLogout: logout,
      userName: _userName,
      userEmail: _userEmail,
      userRole: _userRole,
      apiStatus: _apiStatus,
      apiVerified: _apiVerified,
      checkingApi: _checkingApi,
      onRefreshApi: _verifySession,
      child: AccessScope(
        isAdmin: _currentUser?['role'] == 'admin',
        permissions: _permissions,
        child: currentPage(),
      ),
    );
  }
}
