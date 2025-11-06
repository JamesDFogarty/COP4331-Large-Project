import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/quiz_session.dart';
import '../services/quiz_services.dart';
import 'answer_feedback_screen.dart';
import 'quiz_results_screen.dart';

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
  bool _isWaitingForTeacher = false;  // ADD THIS LINE - was missing!
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

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= widget.session.questions.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      );
    }

    final question = widget.session.questions[_currentQuestionIndex];
    final choices = ['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${_currentQuestionIndex + 1}/${widget.session.totalQuestions}',
          style: const TextStyle(color: Color(0xFFFFD700)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.session.totalQuestions,
                backgroundColor: const Color(0xFF333333),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                minHeight: 8,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: ListView.builder(
                  itemCount: question.choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    final answerText = question.choices[index];
                    final isSelected = _selectedAnswer == choice;
                    final isDisabled = _isSubmitting || _isWaitingForTeacher;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: isDisabled ? null : () => _selectAnswer(choice),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFD700).withOpacity(0.2)
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF333333),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF333333),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    choice,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  answerText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFFFD700),
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isWaitingForTeacher) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _selectedAnswer == null
                          ? 'Select your answer'
                          : _isWaitingForTeacher
                              ? 'Waiting for teacher to advance...'
                              : 'Answer selected!',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedAnswer == null ? Colors.white70 : const Color(0xFFFFD700),
                        fontWeight: _selectedAnswer == null ? FontWeight.normal : FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
