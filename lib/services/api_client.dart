import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final String baseUrl;
  final http.Client _client = http.Client();

  ApiClient._internal() {
    // Android emulator special alias for localhost
    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:8000/api';
    } else {
      // For Windows, Linux, iOS emulator, or custom configurations
      baseUrl = 'http://127.0.0.1:8000/api';
    }
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.get(uri);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to connect to backend: $e');
    }
  }
  
  // You can extend with PATCH, DELETE as needed.

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to connect to backend: $e');
    }
  }

  Future<void> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.delete(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'API Error ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      throw ApiException('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> uploadFile(String endpoint, String filePath) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to upload file: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        'API Error ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    return 'ApiException: $message ${statusCode != null ? "(Status $statusCode)" : ""}\n$body';
  }
}
