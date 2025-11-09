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
  final String pin;

  const QuizQuestionScreen({
    Key? key,
    required this.user,
    required this.session,
    required this.pin,
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
  
  // Store current question data
  late QuizQuestion _currentQuestion;
  late String _testID;
  late int _totalQuestions;
  late String _pin;

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.session.currentQuestion;
    _currentQuestion = widget.session.currentQuestionData;
    _testID = widget.session.testID;
    _totalQuestions = widget.session.totalQuestions;
    _pin = widget.pin;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Helper to convert user.id to int safely
  int _getUserIdAsInt() {
    if (widget.user.id is int) {
      return widget.user.id as int;
    } else if (widget.user.id is String) {
      return int.tryParse(widget.user.id as String) ?? 0;
    }
    return 0;
  }

  Future<void> _selectAnswer(String answer) async {
    if (_isSubmitting || _isWaitingForTeacher) return;

    setState(() {
      _selectedAnswer = answer;
      _isWaitingForTeacher = true;
    });

    await _waitForTeacherToAdvance();
  }

  Future<void> _waitForTeacherToAdvance() async {
    try {
      // This call BLOCKS on the server until teacher advances
      final result = await QuizService.waitForNextQuestion(
        testID: _testID,
        token: widget.user.token ?? '',
      );

      if (!mounted) return;

      if (result['error'] != true) {
        final correctAnswerLetter = result['correctAnswerLetter'] ?? 'A';
        final isCorrect = _selectedAnswer == correctAnswerLetter;

        if (isCorrect) {
          _correctAnswers++;
        }
        _totalAnswered++;

        // Submit the answer with the correct isCorrect value
        await QuizService.submitAnswer(
          testID: _testID,
          studentId: _getUserIdAsInt(), // Convert to int
          answer: _selectedAnswer ?? '',
          isCorrect: isCorrect,
          token: widget.user.token ?? '',
        );

        // Show feedback screen
        final shouldContinue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnswerFeedbackScreen(
              isCorrect: isCorrect,
              correctAnswer: correctAnswerLetter,
              studentAnswer: _selectedAnswer ?? 'No answer',
            ),
          ),
        );

        if (!mounted) return;

        if (shouldContinue == true) {
          // NOW: Rejoin the quiz to get the next question!
          try {
            final updatedSession = await QuizService.joinQuiz(
              _pin,
              _getUserIdAsInt(), // Convert to int
              widget.user.token ?? '',
            );

            if (!mounted) return;

            // Check if quiz ended
            if (!updatedSession.isLive || updatedSession.currentQuestion == -1) {
              _navigateToResults();
              return;
            }

            // Check if we got a new question
            if (updatedSession.currentQuestion > _currentQuestionIndex) {
              // Move to next question!
              setState(() {
                _currentQuestionIndex = updatedSession.currentQuestion;
                _currentQuestion = updatedSession.currentQuestionData;
                _selectedAnswer = null;
                _isWaitingForTeacher = false;
              });
            } else if (updatedSession.currentQuestion == _currentQuestionIndex) {
              // Still on same question? This might mean quiz ended
              if (_totalAnswered >= _totalQuestions) {
                _navigateToResults();
              } else {
                setState(() => _isWaitingForTeacher = false);
              }
            }
          } catch (e) {
            print('Error rejoining quiz: $e');
            if (_totalAnswered >= _totalQuestions) {
              _navigateToResults();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() => _isWaitingForTeacher = false);
              }
            }
          }
        }
      } else {
        // Error from waitQuestion
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
    final choices = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: const Color(0xFF272727),
        title: Text(
          'Question ${_currentQuestionIndex + 1}/$_totalQuestions',
          style: const TextStyle(color: Color(0xFFFFC904)),
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
                value: (_currentQuestionIndex + 1) / _totalQuestions,
                backgroundColor: const Color(0xFF333333),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC904)),
                minHeight: 8,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFC904), width: 2),
                ),
                child: Text(
                  _currentQuestion.questionText,
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
                  itemCount: _currentQuestion.choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    final answerText = _currentQuestion.choices[index];
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
                                ? const Color(0xFFFFC904).withOpacity(0.2)
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFC904)
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
                                      ? const Color(0xFFFFC904)
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
                                    color: isSelected ? const Color(0xFFFFC904) : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFFFC904),
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
                          color: Color(0xFFFFC904),
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
                        color: _selectedAnswer == null ? Colors.white70 : const Color(0xFFFFC904),
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