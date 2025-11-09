// File: lib/services/quiz_session.dart
// This model now works with your API which returns only the current question

class QuizQuestion {
  final String questionText;
  final List<String> choices;

  QuizQuestion({
    required this.questionText,
    required this.choices,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['question'] ?? '',
      choices: List<String>.from(json['options'] ?? []),
    );
  }
}

class QuizSession {
  final String testID;
  final String testName; // Added for waiting room
  final int currentQuestion;
  final int totalQuestions;
  final bool isLive;
  final QuizQuestion currentQuestionData;

  QuizSession({
    required this.testID,
    required this.testName,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.isLive,
    required this.currentQuestionData,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      testID: json['testID'] ?? '',
      testName: json['testID'] ?? '', // Use testID as testName if not provided
      currentQuestion: json['currentQuestion'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      isLive: json['isLive'] ?? false,
      currentQuestionData: QuizQuestion(
        questionText: json['question'] ?? '',
        choices: List<String>.from(json['options'] ?? []),
      ),
    );
  }
}