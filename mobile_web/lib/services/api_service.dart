import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/checkin.dart';
import '../models/user.dart';
import '../models/worksite.dart';

class ApiService {
  ApiService({required this.baseUrl, required this.token});

  final String baseUrl;
  final String? token;

  Map<String, String> _headers({bool jsonBody = true}) {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Credenciales invalidas');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<User> me() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No autorizado');
    }
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Checkin>> getMyCheckins() async {
    final response = await http.get(
      Uri.parse('$baseUrl/checkins/me'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No autorizado');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Checkin.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Checkin> createCheckin({
    required double latitude,
    required double longitude,
    required String activity,
    required XFile photo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/checkins'),
    );
    request.headers.addAll(_headers(jsonBody: false));
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['activity'] = activity;

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: photo.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('photo', photo.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception('No se pudo registrar');
    }
    return Checkin.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No autorizado');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<User> createUser({
    required String fullName,
    required String username,
    required String password,
    required String role,
    int? workSiteId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'username': username,
        'password': password,
        'role': role,
        'workSiteId': workSiteId,
      }),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 201) {
      throw Exception('No se pudo crear el usuario');
    }
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<User> updateUser({
    required int id,
    String? fullName,
    String? username,
    String? password,
    String? role,
    int? workSiteId,
  }) async {
    final payload = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (username != null) 'username': username,
      if (password != null && password.isNotEmpty) 'password': password,
      if (role != null) 'role': role,
      'workSiteId': workSiteId,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: _headers(),
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar el usuario');
    }
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el usuario');
    }
  }

  Future<List<WorkSite>> getWorkSites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/worksites'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No autorizado');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => WorkSite.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<WorkSite> createWorkSite({
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/worksites'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
      }),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 201) {
      throw Exception('No se pudo crear el lugar');
    }
    return WorkSite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<WorkSite> updateWorkSite({
    required int id,
    required String name,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/worksites/$id'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
      }),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar el lugar');
    }
    return WorkSite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteWorkSite(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/worksites/$id'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el lugar');
    }
  }

  Future<List<Checkin>> getAdminCheckins({
    int? employeeId,
    String? type,
    String? from,
    String? to,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/checkins').replace(
      queryParameters: {
        if (employeeId != null) 'employeeId': employeeId.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );

    final response = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No autorizado');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Checkin.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<http.Response> exportCheckins({
    int? employeeId,
    String? type,
    String? from,
    String? to,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/checkins/export').replace(
      queryParameters: {
        if (employeeId != null) 'employeeId': employeeId.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );

    final response = await http
        .get(uri, headers: _headers(jsonBody: false))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No se pudo exportar');
    }
    return response;
  }
}
