// File: lib/services/quiz_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'quiz_session.dart';

// Platform-specific imports
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show HttpClient, X509Certificate;
import 'package:http/io_client.dart';

class QuizService {
  static const String baseUrl = 'https://174.138.73.101:5173/api';

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

  // Join a quiz using PIN
  static Future<QuizSession> joinQuiz(String pin, int studentId, String token) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/joinTest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'PIN': pin,
          'ID': studentId, // API expects int
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizSession.fromJson(data);
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

  // Get current quiz status (same as joinQuiz, just for checking status)
  static Future<QuizSession> getQuizStatus(String pin, int studentId, String token) async {
    // This is the same as joinQuiz - your API doesn't have a separate status endpoint
    return joinQuiz(pin, studentId, token);
  }

  // Submit answer
  static Future<bool> submitAnswer({
    required String testID,
    required int studentId,
    required String answer,
    required bool isCorrect,
    required String token,
  }) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/submitQuestion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ID': studentId, // API expects int
          'testID': testID,
          'isCorrect': isCorrect,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Submit answer error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  // Wait for teacher to advance to next question
  // Returns the correct answer index when teacher advances
  static Future<Map<String, dynamic>> waitForNextQuestion({
    required String testID,
    required String token,
  }) async {
    final client = _getHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/waitQuestion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'testID': testID,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API returns { answer: 1 } where answer is the index of correct option (0-3)
        return {
          'error': false,
          'correctAnswerIndex': data['answer'],
          'correctAnswerLetter': _convertIndexToLetter(data['answer']),
        };
      } else {
        return {'error': true};
      }
    } catch (e) {
      print('Wait for next question error: $e');
      return {'error': true};
    } finally {
      client.close();
    }
  }

  // Helper function to convert answer index to letter
  static String _convertIndexToLetter(int index) {
  const letters = ['A', 'B', 'C', 'D'];
  // Subtract 1 because API uses 1-based indexing
  final adjustedIndex = index - 1;  // ✅ Now 1→A, 2→B, etc.
  if (adjustedIndex >= 0 && adjustedIndex < letters.length) {
    return letters[adjustedIndex];
  }
  return 'A';
}

  // Helper function to convert letter to index
  static int _convertLetterToIndex(String letter) {
    const letters = {'A': 0, 'B': 1, 'C': 2, 'D': 3};
    return letters[letter.toUpperCase()] ?? 0;
  }
}