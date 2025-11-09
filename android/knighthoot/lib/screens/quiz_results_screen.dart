import 'package:flutter/material.dart';
import '../models/user.dart';
import 'join_quiz_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  final User user;
  final int correctAnswers;
  final int totalQuestions;

  const QuizResultsScreen({
    Key? key,
    required this.user,
    required this.correctAnswers,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: const Color(0xFF272727),
        title: const Text(
          'Quiz Results', 
          style: TextStyle(color: Color(0xFFFFC904)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correctAnswers >= totalQuestions * 0.7
                    ? Icons.emoji_events
                    : Icons.star,
                size: 100,
                color: const Color(0xFFFFC904),
              ),
              const SizedBox(height: 24),

              const Text(
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFC904),
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF272727),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC904), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '$correctAnswers / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFC904),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Correct Answers',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                _getPerformanceMessage(correctAnswers / totalQuestions),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinQuizScreen(user: user),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC904),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'RETURN TO HOME',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPerformanceMessage(double ratio) {
    if (ratio >= 0.9) return 'Outstanding! Perfect score! 🎉';
    if (ratio >= 0.7) return 'Great job! Well done! 👍';
    if (ratio >= 0.5) return 'Good effort! Keep practicing! 💪';
    return 'Keep learning and try again! 📚';
  }
}