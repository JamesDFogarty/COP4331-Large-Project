import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/quiz_session.dart';
import '../services/quiz_services.dart';
import 'answer_feedback_screen.dart';
import 'quiz_results_screen.dart';
import 'join_quiz_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  final User user;
  final QuizSession session;

  const QuizQuestionScreen({
    Key? key,
    required this.user,
    required this.session,
  }) : super(key: key);

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  String? _selectedAnswer;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _isWaitingForTeacher = false;
  int _correctAnswers = 0;
  int _totalAnswered = 0;

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.session.currentQuestion;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF272727),
          title: const Text(
            'Exit Test',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to exit the test? Your progress will be lost.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate back to join quiz screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JoinQuizScreen(user: widget.user),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Exit',
                style: TextStyle(color: Color(0xFFFFC904)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectAnswer(String answer) async {
    if (_isSubmitting || _isWaitingForTeacher) return;

    setState(() {
      _selectedAnswer = answer;
      _isSubmitting = true;
    });

    // Submit answer to backend with token
    final success = await QuizService.submitAnswer(
      testID: widget.session.testID,
      studentId: widget.user.id,
      questionIndex: _currentQuestionIndex,
      answer: answer,
      token: widget.user.token ?? '',
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit answer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
          _selectedAnswer = null;
        });
      }
      return;
    }

    // Answer submitted successfully, now wait for teacher
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isWaitingForTeacher = true;
      });

      _waitForTeacherToAdvance();
    }
  }

  Future<void> _waitForTeacherToAdvance() async {
    try {
      // This call blocks on the server until teacher advances
      final result = await QuizService.waitForNextQuestion(
        testID: widget.session.testID,
        token: widget.user.token ?? '',
      );

      if (!mounted) return;

      if (result['error'] != true) {
        final correctAnswer = result['correctAnswer'] ?? '';
        final isCorrect = _selectedAnswer == correctAnswer;

        if (isCorrect) {
          _correctAnswers++;
        }
        _totalAnswered++;

        // Show feedback screen
        final shouldContinue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnswerFeedbackScreen(
              isCorrect: isCorrect,
              correctAnswer: correctAnswer,
              studentAnswer: _selectedAnswer ?? 'No answer',
              currentScore: _correctAnswers,
              totalQuestions: widget.session.totalQuestions,
              user: widget.user,
              testID: widget.session.testID,
              questionNumber: _currentQuestionIndex + 1,
            ),
          ),
        );

        if (shouldContinue == true && mounted) {
          // Check if quiz has ended
          final updatedSession = await QuizService.getQuizStatus(
            widget.session.testID,
            widget.user.token ?? '',
          );
          
          if (!updatedSession.isLive && updatedSession.currentQuestion == -1) {
            // Quiz ended
            _navigateToResults();
          } else if (updatedSession.currentQuestion > _currentQuestionIndex) {
            // Move to next question
            setState(() {
              _currentQuestionIndex = updatedSession.currentQuestion;
              _selectedAnswer = null;
              _isWaitingForTeacher = false;
            });
          }
        }
      } else {
        // Error occurred
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection error. Please check your internet.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isWaitingForTeacher = false);
        }
      }
    } catch (e) {
      print('Error waiting for teacher: $e');
      if (mounted) {
        setState(() => _isWaitingForTeacher = false);
      }
    }
  }

  void _navigateToResults() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          user: widget.user,
          correctAnswers: _correctAnswers,
          totalQuestions: _totalAnswered,
        ),
      ),
    );
  }

  Color _getChoiceColor(String choice) {
    switch (choice) {
      case 'A':
        return const Color(0xFFCC9D00); // Darker Yellow
      case 'B':
        return const Color(0xFF9E9E9E); // Gray
      case 'C':
        return const Color(0xFF8B7010); // Darker Gold/Brown
      case 'D':
        return const Color(0xFF616161); // Dark Gray
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= widget.session.questions.length) {
      return const Scaffold(
        backgroundColor: Color(0xFF171717),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFC904))),
      );
    }

    final question = widget.session.questions[_currentQuestionIndex];
    final choices = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: const Color(0xFF272727),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _showExitDialog,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Text(
              'PIN: ${widget.session.testID}',
              style: const TextStyle(
                color: Color(0xFFFFC904),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1} of ${widget.session.totalQuestions}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
            child: Column(
              children: [
                // Question text at top
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Answer choices grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: List.generate(
                        question.choices.length > 4 ? 4 : question.choices.length,
                        (index) {
                          final choice = choices[index];
                          final answerText = question.choices[index];
                          final isSelected = _selectedAnswer == choice;
                          final isDisabled = _isSubmitting || _isWaitingForTeacher;
                          final choiceColor = _getChoiceColor(choice);

                          return InkWell(
                            onTap: isDisabled ? null : () => _selectAnswer(choice),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? choiceColor.withOpacity(0.3)
                                    : choiceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    choice,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      answerText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom info bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF272727),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Student name
                      Text(
                        '${widget.user.firstName} ${widget.user.lastName.substring(0, 1)}.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Status or score
                      if (_isWaitingForTeacher)
                        Row(
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFC904),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Waiting...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFFC904),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '-/${widget.session.totalQuestions}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}