import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/quiz_session.dart';

class QuizService {
  static const String baseUrl = 'http://174.138.73.101:5173/api';

  /// Join a quiz using PIN (requires auth token)
  static Future<QuizSession> joinQuiz(String pin, String studentId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/joinTest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // ADD AUTH HEADER
        },
        body: jsonEncode({
          'PIN': pin,
          'ID': studentId,
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
    }
  }

  /// Get current quiz status (requires auth token)
  static Future<QuizSession> getQuizStatus(String testID, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test/$testID'),
        headers: {
          'Authorization': 'Bearer $token',  // ADD AUTH HEADER
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizSession.fromJson(data);
      } else {
        throw Exception('Failed to get quiz status');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Submit student's answer (requires auth token)
  static Future<bool> submitAnswer({
    required String testID,
    required String studentId,
    required int questionIndex,
    required String answer,
    required String token,  // ADD THIS
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/submitQuestion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // ADD AUTH HEADER
        },
        body: jsonEncode({
          'ID': studentId,
          'testID': testID,
          'questionIndex': questionIndex,
          'selectedAnswer': answer,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting answer: $e');
      return false;
    }
  }

  /// Wait for teacher to advance (requires auth token)
  static Future<Map<String, dynamic>> waitForNextQuestion({
    required String testID,
    required String token,  // ADD THIS
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/waitQuestion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // ADD AUTH HEADER
        },
        body: jsonEncode({
          'testID': testID,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'correctAnswer': data['answer'],
          'error': false,
        };
      } else {
        return {'error': true};
      }
    } catch (e) {
      print('Error waiting for question: $e');
      return {'error': true};
    }
  }
}