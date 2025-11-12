// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/test_score.dart';

// Platform-specific imports
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show HttpClient, X509Certificate;
import 'package:http/io_client.dart';

class ApiService {
  static const String baseUrl = 'https://knighthoot.app/api';

  // ⚠️ WARNING: This bypasses SSL certificate verification on mobile/desktop
  // ONLY use for development with self-signed certificates
  // REMOVE this before deploying to production!
  static http.Client _getHttpClient() {
    if (kIsWeb) {
      // Web doesn't support custom HttpClient, use default
      // Note: Web browsers handle SSL differently and may still show warnings
      return http.Client();
    } else {
      // Mobile/Desktop: bypass certificate verification
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return IOClient(httpClient);
    }
  }

  static Future<User> login(String username, String password) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    required String email,
    required bool isTeacher,
  }) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'password': password,
          'email': email,
          'isTeacher': isTeacher,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<bool> checkEmailExists(String email) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/emailExists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        return false;
      } else {
        throw Exception('Failed to check email');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> sendOtpEmail(String email) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to send verification email');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<void> sendForgotPasswordEmail(String email) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Success - OTP saved to database and email sent
        return;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> updatePassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> startTest(String testCode) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/test/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'testCode': testCode,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to join quiz');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }

  static Future<List<TestScore>> getStudentScores(
      User user, String token) async {
    final client = _getHttpClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/score/student/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Extract firstName and lastName from the User object
        String userFirstName = user.firstName;
        String userLastName = user.lastName;
        
        return data.map((json) {
          return TestScore.fromJson(
            json,
            firstName: userFirstName,
            lastName: userLastName,
          );
        }).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch scores');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    } finally {
      client.close();
    }
  }
}