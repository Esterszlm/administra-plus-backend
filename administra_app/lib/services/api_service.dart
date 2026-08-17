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

  dynamic _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void _validateResponse(http.Response response, String errorMessage) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(errorMessage);
    }
  }

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
      throw Exception('Erro no login. Verifique e-mail e senha.');
    }

    final data = _decodeResponse(response);

    final accessToken = data['access_token'];

    if (accessToken == null) {
      throw Exception('Token não encontrado na resposta do backend.');
    }

    return accessToken;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: _headers,
    );

    _validateResponse(response, 'Erro ao carregar dashboard.');

    return _decodeResponse(response);
  }

  Future<List<dynamic>> getOrganizations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/organizations/'),
      headers: _headers,
    );

    _validateResponse(response, 'Erro ao carregar organizações.');

    return _decodeResponse(response);
  }

  Future<List<dynamic>> getEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/'),
      headers: _headers,
    );

    _validateResponse(response, 'Erro ao carregar eventos.');

    return _decodeResponse(response);
  }

  Future<List<dynamic>> getFinance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/finance/'),
      headers: _headers,
    );

    _validateResponse(response, 'Erro ao carregar financeiro.');

    return _decodeResponse(response);
  }
}