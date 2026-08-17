import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdministraApp());
}

class AdministraApp extends StatelessWidget {
  const AdministraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Administra+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController(text: 'admin@email.com');
  final passwordController = TextEditingController(text: '123456');

  bool carregando = false;
  String mensagem = '';

  final String apiUrl = 'http://127.0.0.1:8000';

  Future<void> login() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/users/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': emailController.text.trim(),
          'password': passwordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['access_token'];

        if (token != null) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                token: token,
                apiUrl: apiUrl,
              ),
            ),
          );
        } else {
          setState(() {
            mensagem = 'Token não encontrado na resposta.';
          });
        }
      } else {
        setState(() {
          mensagem = 'Erro no login. Verifique e-mail e senha.';
        });
      }
    } catch (e) {
      setState(() {
        mensagem =
            'Erro ao conectar com o backend. Verifique se a API está rodando.';
      });
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.business_center,
                size: 58,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              const Text(
                'Administra+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Acesse o painel administrativo',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: carregando ? null : login,
                  child: carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 16),
              if (mensagem.isNotEmpty)
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String token;
  final String apiUrl;

  const HomePage({
    super.key,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paginaSelecionada = 0;

  final List<String> titulos = [
    'Dashboard',
    'Organizações',
    'Eventos',
    'Financeiro',
  ];

  void trocarPagina(int index) {
    setState(() {
      paginaSelecionada = index;
    });
    Navigator.pop(context);
  }

  void sair() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Widget paginaAtual() {
    if (paginaSelecionada == 0) {
      return DashboardPage(
        token: widget.token,
        apiUrl: widget.apiUrl,
      );
    }

    if (paginaSelecionada == 1) {
      return OrganizationsPage(
        token: widget.token,
        apiUrl: widget.apiUrl,
      );
    }

    if (paginaSelecionada == 2) {
      return EventsPage(
        token: widget.token,
        apiUrl: widget.apiUrl,
      );
    }

    return FinancePage(
      token: widget.token,
      apiUrl: widget.apiUrl,
    );
  }

  Widget itemMenu({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: paginaSelecionada == index,
      selectedTileColor: Colors.indigo.withOpacity(0.08),
      selectedColor: Colors.indigo,
      onTap: () => trocarPagina(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${titulos[paginaSelecionada]} — Administra+'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.business_center,
                      color: Colors.white,
                      size: 42,
                    ),
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
            itemMenu(
              icon: Icons.dashboard,
              title: 'Dashboard',
              index: 0,
            ),
            itemMenu(
              icon: Icons.apartment,
              title: 'Organizações',
              index: 1,
            ),
            itemMenu(
              icon: Icons.event,
              title: 'Eventos',
              index: 2,
            ),
            itemMenu(
              icon: Icons.receipt_long,
              title: 'Financeiro',
              index: 3,
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: sair,
            ),
          ],
        ),
      ),
      body: paginaAtual(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String token;
  final String apiUrl;

  const DashboardPage({
    super.key,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool carregando = true;
  String mensagem = '';

  Map<String, dynamic>? dashboard;

  Future<void> buscarDashboard() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/dashboard/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          dashboard = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else if (response.statusCode == 403) {
        setState(() {
          mensagem = 'Usuário sem permissão para acessar o dashboard.';
        });
      } else {
        setState(() {
          mensagem = 'Erro ao carregar dashboard.';
        });
      }
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao conectar com o backend.';
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    buscarDashboard();
  }

  Widget cardResumo(String titulo, String valor, IconData icone) {
    return Card(
      elevation: 2,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 32, color: Colors.indigo),
            const SizedBox(height: 14),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatarValor(dynamic valor) {
    final numero = double.tryParse(valor.toString()) ?? 0;
    return 'R\$ ${numero.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final totais = dashboard?['totais'];
    final financeiro = dashboard?['financeiro'];

    return Container(
      color: const Color(0xfff5f6fa),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : mensagem.isNotEmpty
                ? Center(
                    child: Text(
                      mensagem,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo geral do sistema',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Informações consolidadas do backend Administra+.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            cardResumo(
                              'Organizações',
                              '${totais?['organizacoes'] ?? 0}',
                              Icons.apartment,
                            ),
                            cardResumo(
                              'Usuários',
                              '${totais?['usuarios'] ?? 0}',
                              Icons.people,
                            ),
                            cardResumo(
                              'Eventos',
                              '${totais?['eventos'] ?? 0}',
                              Icons.event,
                            ),
                            cardResumo(
                              'Confirmações',
                              '${totais?['confirmacoes'] ?? 0}',
                              Icons.check_circle,
                            ),
                            cardResumo(
                              'Lançamentos',
                              '${totais?['lancamentos_financeiros'] ?? 0}',
                              Icons.receipt_long,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Resumo financeiro',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            cardResumo(
                              'Entradas',
                              formatarValor(
                                financeiro?['total_entradas'] ?? 0,
                              ),
                              Icons.arrow_downward,
                            ),
                            cardResumo(
                              'Saídas',
                              formatarValor(
                                financeiro?['total_saidas'] ?? 0,
                              ),
                              Icons.arrow_upward,
                            ),
                            cardResumo(
                              'Saldo final',
                              formatarValor(
                                financeiro?['saldo_final'] ?? 0,
                              ),
                              Icons.account_balance_wallet,
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

class OrganizationsPage extends StatefulWidget {
  final String token;
  final String apiUrl;

  const OrganizationsPage({
    super.key,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  bool carregando = true;
  String mensagem = '';
  List<dynamic> organizations = [];

  Future<void> buscarOrganizations() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/organizations/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          organizations = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else if (response.statusCode == 403) {
        setState(() {
          mensagem = 'Usuário sem permissão para listar organizações.';
        });
      } else {
        setState(() {
          mensagem = 'Erro ao carregar organizações.';
        });
      }
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao conectar com o backend.';
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    buscarOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    return ListPageLayout(
      titulo: 'Organizações cadastradas',
      subtitulo: 'Consulta das organizações registradas no sistema.',
      carregando: carregando,
      mensagem: mensagem,
      vazioMensagem: 'Nenhuma organização cadastrada.',
      onRefresh: buscarOrganizations,
      children: organizations.map((item) {
        return InfoCard(
          icon: Icons.apartment,
          title: texto(item['name']),
          subtitle: 'Documento: ${texto(item['document'])}',
          rows: [
            InfoRow(label: 'ID', value: texto(item['id'])),
            InfoRow(label: 'Tipo', value: texto(item['type'])),
            InfoRow(label: 'Cidade', value: texto(item['city'])),
            InfoRow(label: 'Estado', value: texto(item['state'])),
            InfoRow(
              label: 'Responsável',
              value: texto(item['responsible_name']),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class EventsPage extends StatefulWidget {
  final String token;
  final String apiUrl;

  const EventsPage({
    super.key,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool carregando = true;
  String mensagem = '';
  List<dynamic> events = [];

  Future<void> buscarEvents() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/events/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          events = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else if (response.statusCode == 403) {
        setState(() {
          mensagem = 'Usuário sem permissão para listar eventos.';
        });
      } else {
        setState(() {
          mensagem = 'Erro ao carregar eventos.';
        });
      }
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao conectar com o backend.';
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    buscarEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ListPageLayout(
      titulo: 'Eventos cadastrados',
      subtitulo: 'Consulta dos eventos registrados no sistema.',
      carregando: carregando,
      mensagem: mensagem,
      vazioMensagem: 'Nenhum evento cadastrado.',
      onRefresh: buscarEvents,
      children: events.map((item) {
        return InfoCard(
          icon: Icons.event,
          title: texto(item['title']),
          subtitle: 'Local: ${texto(item['location'])}',
          rows: [
            InfoRow(label: 'ID', value: texto(item['id'])),
            InfoRow(label: 'Descrição', value: texto(item['description'])),
            InfoRow(label: 'Data', value: formatarData(item['date'])),
            InfoRow(
              label: 'Organização',
              value: texto(
                item['organization_name'] ?? item['organization_id'],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class FinancePage extends StatefulWidget {
  final String token;
  final String apiUrl;

  const FinancePage({
    super.key,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool carregando = true;
  String mensagem = '';
  List<dynamic> finances = [];

  Future<void> buscarFinances() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/finance/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          finances = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else if (response.statusCode == 403) {
        setState(() {
          mensagem = 'Usuário sem permissão para listar financeiro.';
        });
      } else {
        setState(() {
          mensagem = 'Erro ao carregar financeiro.';
        });
      }
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao conectar com o backend.';
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    buscarFinances();
  }

  @override
  Widget build(BuildContext context) {
    return ListPageLayout(
      titulo: 'Lançamentos financeiros',
      subtitulo: 'Consulta das entradas e saídas registradas no sistema.',
      carregando: carregando,
      mensagem: mensagem,
      vazioMensagem: 'Nenhum lançamento financeiro cadastrado.',
      onRefresh: buscarFinances,
      children: finances.map((item) {
        return InfoCard(
          icon: Icons.receipt_long,
          title: texto(item['description']),
          subtitle: 'Valor: ${formatarValor(item['amount'])}',
          rows: [
            InfoRow(label: 'ID', value: texto(item['id'])),
            InfoRow(label: 'Tipo', value: texto(item['type'])),
            InfoRow(label: 'Valor', value: formatarValor(item['amount'])),
            InfoRow(
              label: 'Organização',
              value: texto(
                item['organization_name'] ?? item['organization_id'],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ListPageLayout extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool carregando;
  final String mensagem;
  final String vazioMensagem;
  final VoidCallback onRefresh;
  final List<Widget> children;

  const ListPageLayout({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.carregando,
    required this.mensagem,
    required this.vazioMensagem,
    required this.onRefresh,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfff5f6fa),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : mensagem.isNotEmpty
                ? Center(
                    child: Text(
                      mensagem,
                      style: const TextStyle(color: Colors.red),
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
                                    titulo,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitulo,
                                    style:
                                        const TextStyle(color: Colors.black54),
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
                            vazioMensagem,
                            style: const TextStyle(color: Colors.black54),
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

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<InfoRow> rows;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.indigo, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(height: 28),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        '${row.label}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(row.value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow {
  final String label;
  final String value;

  InfoRow({
    required this.label,
    required this.value,
  });
}

String texto(dynamic valor) {
  if (valor == null) {
    return '-';
  }

  final texto = valor.toString().trim();

  if (texto.isEmpty) {
    return '-';
  }

  return texto;
}

String formatarValor(dynamic valor) {
  final numero = double.tryParse(valor.toString()) ?? 0;
  return 'R\$ ${numero.toStringAsFixed(2)}';
}

String formatarData(dynamic valor) {
  if (valor == null) {
    return '-';
  }

  return valor.toString().replaceAll('T', ' ');
}