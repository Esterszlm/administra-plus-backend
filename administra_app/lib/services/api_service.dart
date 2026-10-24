
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String? token;

  const ApiService({
    required this.baseUrl,
    this.token,
  });

  Map<String, String> get _headers {
    final headers = <String, String>{};

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, String> get _jsonHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void _validateResponse(
    http.Response response,
    String errorMessage,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String message = errorMessage;

    try {
      final data = _decodeResponse(response);

      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];

        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          message = detail.map((item) {
            if (item is Map && item['msg'] != null) {
              return item['msg'].toString();
            }
            return item.toString();
          }).join('; ');
        } else {
          message = detail.toString();
        }
      }
    } catch (_) {
      // Mantém a mensagem padrão se a API não retornar JSON válido.
    }

    throw Exception(message);
  }

  // ==========================================================
  // AUTENTICAÇÃO
  // ==========================================================

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': username.trim(),
        'password': password.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro no login. Verifique e-mail e senha.',
      );
    }

    final data = _decodeResponse(response);
    final accessToken = data['access_token'];

    if (accessToken == null) {
      throw Exception(
        'Token não encontrado na resposta do backend.',
      );
    }

    return accessToken;
  }

  // ==========================================================
  // DASHBOARD
  // ==========================================================

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao carregar dashboard.',
    );

    return _decodeResponse(response);
  }

  // ==========================================================
  // ORGANIZAÇÕES
  // ==========================================================

  Future<List<dynamic>> getOrganizations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/organizations/'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao carregar organizações.',
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String type,
    required String document,
    required String address,
    required String city,
    required String state,
    required String responsibleName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/organizations/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name.trim(),
        'type': type.trim(),
        'document': document.trim(),
        'address': address.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'responsible_name': responsibleName.trim(),
      }),
    );

    _validateResponse(
      response,
      'Erro ao cadastrar organização.',
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateOrganization({
    required int id,
    required String name,
    required String type,
    required String document,
    required String address,
    required String city,
    required String state,
    required String responsibleName,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name.trim(),
        'type': type.trim(),
        'document': document.trim(),
        'address': address.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'responsible_name': responsibleName.trim(),
      }),
    );

    _validateResponse(
      response,
      'Erro ao editar organização.',
    );

    return _decodeResponse(response);
  }

  Future<void> deleteOrganization(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao excluir organização.',
    );
  }

  // ==========================================================
  // EVENTOS
  // ==========================================================

  Future<List<dynamic>> getEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao carregar eventos.',
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String date,
    required String location,
    required int organizationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'title': title.trim(),
        'description': description.trim(),
        'date': date.trim(),
        'location': location.trim(),
        'organization_id': organizationId,
      }),
    );

    _validateResponse(
      response,
      'Erro ao cadastrar evento.',
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateEvent({
    required int id,
    required String title,
    required String description,
    required String date,
    required String location,
    required int organizationId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/events/$id'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'title': title.trim(),
        'description': description.trim(),
        'date': date.trim(),
        'location': location.trim(),
        'organization_id': organizationId,
      }),
    );

    _validateResponse(
      response,
      'Erro ao editar evento.',
    );

    return _decodeResponse(response);
  }

  Future<void> deleteEvent(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$id'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao excluir evento.',
    );
  }

  // ==========================================================
  // FINANCEIRO
  // ==========================================================

  Future<List<dynamic>> getFinance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/finance/'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao carregar financeiro.',
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> createFinance({
    required String type,
    required double amount,
    required String description,
    required int organizationId,
    int? userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/finance/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'type': type.trim(),
        'amount': amount,
        'description': description.trim(),
        'organization_id': organizationId,
        'user_id': userId,
      }),
    );

    _validateResponse(
      response,
      'Erro ao cadastrar lançamento financeiro.',
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> updateFinance({
    required int id,
    required String type,
    required double amount,
    required String description,
    required int organizationId,
    int? userId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/finance/$id'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'type': type.trim(),
        'amount': amount,
        'description': description.trim(),
        'organization_id': organizationId,
        'user_id': userId,
      }),
    );

    _validateResponse(
      response,
      'Erro ao editar lançamento financeiro.',
    );

    return _decodeResponse(response);
  }

  Future<void> deleteFinance(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/finance/$id'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao excluir lançamento financeiro.',
    );
  }

  // ==========================================================
  // USUÁRIOS - NOVO MÓDULO
  // ==========================================================

  // GET /users/
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao carregar usuários.',
    );

    return _decodeResponse(response);
  }

  // POST /users/
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    int? organizationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role.trim().toLowerCase(),
        'organization_id': organizationId,
      }),
    );

    _validateResponse(
      response,
      'Erro ao cadastrar usuário.',
    );

    return _decodeResponse(response);
  }

  // PUT /users/{user_id}
  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
    int? organizationId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': role.trim().toLowerCase(),
        'organization_id': organizationId,
      }),
    );

    _validateResponse(
      response,
      'Erro ao atualizar usuário.',
    );

    return _decodeResponse(response);
  }

  // DELETE /users/{user_id}
  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao excluir usuário.',
    );
  }
  // RESUMO FINANCEIRO POR USUÁRIO
  Future<Map<String, dynamic>> getUserFinanceSummary(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/finance/users/$userId/summary'),
      headers: _headers,
    );

    _validateResponse(
      response,
      'Erro ao carregar o financeiro do usuário.',
    );

    final data = _decodeResponse(response);

    return Map<String, dynamic>.from(data);
  }

  // PATCH /users/{id}/deactivate - preserva financeiro e histórico
  Future<Map<String, dynamic>> deactivateUser(int id, String reason) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id/deactivate'),
      headers: _jsonHeaders,
      body: jsonEncode({'reason': reason.trim()}),
    );
    _validateResponse(response, 'Erro ao desativar usuário.');
    return Map<String, dynamic>.from(_decodeResponse(response));
  }

  // PATCH /users/{id}/reactivate
  Future<Map<String, dynamic>> reactivateUser(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id/reactivate'),
      headers: _headers,
    );
    _validateResponse(response, 'Erro ao reativar usuário.');
    return Map<String, dynamic>.from(_decodeResponse(response));
  }
}
