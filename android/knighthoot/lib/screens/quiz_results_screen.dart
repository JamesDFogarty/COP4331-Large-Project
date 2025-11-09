import 'package:flutter/material.dart';
import '../models/user.dart';
import 'join_quiz_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  final User user;
  final int correctAnswers;
  final int totalQuestions;
  final String? testName;

  const QuizResultsScreen({
    Key? key,
    required this.user,
    required this.correctAnswers,
    required this.totalQuestions,
    this.testName,
  }) : super(key: key);

  String _formatDate() {
    final now = DateTime.now();
    return '${now.month}/${now.day}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: const Color(0xFF272727),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => JoinQuizScreen(user: user),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Test Complete',
          style: TextStyle(
            color: Color(0xFFFFC904),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background decorative squares
          Positioned(
            top: 50,
            right: 30,
            child: _buildHollowSquare(200, 2),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: _buildHollowSquare(200, 2),
          ),
          Positioned(
            bottom: 200,
            right: 50,
            child: _buildHollowSquare(80, 2),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            child: _buildHollowSquare(50, 2),
          ),
          Positioned(
            top: 300,
            right: 70,
            child: _buildHollowSquare(35, 2),
          ),
          Positioned(
            top: 400,
            left: 60,
            child: _buildHollowSquare(45, 2),
          ),
          Positioned(
            bottom: 200,
            left: 80,
            child: _buildHollowSquare(150, 2),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Results Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF272727),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Test Name
                          Text(
                            testName ?? 'Exam 3',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // "by Student Name"
                          Text(
                            'by ${user.firstName} ${user.lastName.substring(0, 1)}.',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Date
                          Text(
                            _formatDate(),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Final Score
                          RichText(
                            text: TextSpan(
                              text: 'Final Score: ',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: '$correctAnswers/$totalQuestions',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color(0xFFFFC904),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Return Home Button
                    SizedBox(
                      width: double.infinity,
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Return Home',
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
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF272727),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${user.firstName} ${user.lastName.substring(0, 1)}.',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$correctAnswers/$totalQuestions',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHollowSquare(double size, double borderWidth) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF272727),
          width: borderWidth,
        ),
      ),
    );
  }
}