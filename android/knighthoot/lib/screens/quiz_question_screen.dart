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
  final String pin; // CRITICAL: Need PIN to rejoin!

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
  // FIXED: Track questions attempted (answered + timed out) separately from total questions in test
  int _questionsAttempted = 0;
  
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
    
    // Start waiting for teacher immediately (handles case where teacher advances before student answers)
    _waitForTeacherToAdvance();
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
    if (_isSubmitting) return; // Only block if submitting, not if waiting

    setState(() {
      _selectedAnswer = answer;
    });
  }

  Future<void> _waitForTeacherToAdvance() async {
    if (_isWaitingForTeacher) return; // Prevent duplicate calls
    
    setState(() => _isWaitingForTeacher = true);
    
    try {
      // This call BLOCKS on the server until teacher advances
      final result = await QuizService.waitForNextQuestion(
        testID: _testID,
        token: widget.user.token ?? '',
      );

      if (!mounted) return;

      if (result['error'] != true) {
        final correctAnswerLetter = result['correctAnswerLetter'] ?? 'A';
        final didAnswer = _selectedAnswer != null;
        final isCorrect = didAnswer && (_selectedAnswer == correctAnswerLetter);

        // FIXED: Increment questionsAttempted regardless of whether they answered
        _questionsAttempted++;

        if (didAnswer && isCorrect) {
          _correctAnswers++;
        }

        // Submit the answer - if they didn't answer, submit as incorrect
        await QuizService.submitAnswer(
          testID: _testID,
          studentId: _getUserIdAsInt(),
          answer: _selectedAnswer ?? '',
          isCorrect: didAnswer ? isCorrect : false,
          token: widget.user.token ?? '',
        );

        // Show feedback screen with UI updates
        final shouldContinue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnswerFeedbackScreen(
              isCorrect: didAnswer ? isCorrect : false,
              correctAnswer: correctAnswerLetter,
              studentAnswer: didAnswer ? _selectedAnswer! : 'No answer (Time ran out)',
              currentScore: _correctAnswers,
              // FIXED: Pass questionsAttempted instead of totalQuestions
              totalQuestions: _questionsAttempted,
              user: widget.user,
              testID: _pin, // Pass PIN not testID for display
              questionNumber: _currentQuestionIndex + 1,
            ),
          ),
        );

        if (!mounted) return;

        if (shouldContinue == true) {
          // NOW: Rejoin the quiz to get the next question!
          try {
            final updatedSession = await QuizService.joinQuiz(
              _pin,
              _getUserIdAsInt(),
              widget.user.token ?? '',
            );

            if (!mounted) return;

            // Check if quiz ended (isLive=false OR currentQuestion=-1)
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
              
              // Start waiting for teacher on new question
              _waitForTeacherToAdvance();
            } else {
              // Still on same question or quiz ended
              _navigateToResults();
            }
          } catch (e) {
            print('Error rejoining quiz: $e');
            // Error rejoining likely means quiz ended - navigate to results
            if (mounted) {
              _navigateToResults();
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
      print('Wait for next question error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Returning to home.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => JoinQuizScreen(user: widget.user),
          ),
          (route) => false,
        );
      }
    }
  }

  void _navigateToResults() {
    // FIXED: Pass questionsAttempted instead of totalQuestions
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          user: widget.user,
          correctAnswers: _correctAnswers,
          totalQuestions: _questionsAttempted,
          testName: _testID,
        ),
      ),
    );
  }

  // Color mapping for answer choices
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

  @override
  Widget build(BuildContext context) {
    const choices = ['A', 'B', 'C', 'D'];

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF171717),
        appBar: AppBar(
          backgroundColor: const Color(0xFF272727),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _showExitDialog,
          ),
          title: Text(
            'PIN: $_pin',
            style: const TextStyle(
              color: Color(0xFFFFC904),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentQuestionIndex + 1} of $_totalQuestions',
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
                    _currentQuestion.questionText,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: constraints.maxWidth / (constraints.maxHeight * 0.95),
                          ),
                          itemCount: _currentQuestion.choices.length > 4 ? 4 : _currentQuestion.choices.length,
                          itemBuilder: (context, index) {
                            final choice = choices[index];
                            final answerText = _currentQuestion.choices[index];
                            final isSelected = _selectedAnswer == choice;
                            final isDisabled = _isSubmitting; // Only disable when submitting, not when waiting
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
                                child: Stack(
                                  children: [
                                    // Letter in top-left corner
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Text(
                                        choice,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    // Answer text centered
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          answerText,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
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
                      
                      // Status or score - FIXED: Display questionsAttempted
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
                          '$_correctAnswers/$_questionsAttempted',
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