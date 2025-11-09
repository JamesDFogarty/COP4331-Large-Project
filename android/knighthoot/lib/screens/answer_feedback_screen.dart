import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import 'join_quiz_screen.dart';

class AnswerFeedbackScreen extends StatefulWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String studentAnswer;
  final int currentScore;
  final int totalQuestions;
  final User user;
  final String testID;
  final int questionNumber;

  const AnswerFeedbackScreen({
    Key? key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.studentAnswer,
    required this.currentScore,
    required this.totalQuestions,
    required this.user,
    required this.testID,
    required this.questionNumber,
  }) : super(key: key);

  @override
  State<AnswerFeedbackScreen> createState() => _AnswerFeedbackScreenState();
}

class _AnswerFeedbackScreenState extends State<AnswerFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // AUTO-ADVANCE after 3 seconds
    _autoAdvanceTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context, true); // Return true to continue
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showExitDialog() {
    _autoAdvanceTimer?.cancel(); // Pause auto-advance while showing dialog
    
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
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Resume auto-advance
                _autoAdvanceTimer = Timer(const Duration(seconds: 3), () {
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate back to join quiz screen and clear all routes
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button, must use exit dialog
        _showExitDialog();
        return false;
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
            'PIN: ${widget.testID}',
            style: const TextStyle(
              color: Color(0xFFFFC904),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${widget.questionNumber} of ${widget.totalQuestions}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF272727),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Check/X icon in circle
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: widget.isCorrect ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isCorrect ? Icons.check : Icons.close,
                              size: 120,
                              color: Colors.black,
                              weight: 700,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Correct/Incorrect text
                          Text(
                            widget.isCorrect ? 'Correct' : 'Incorrect',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Answer information
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your answer:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.studentAnswer,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: widget.isCorrect ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (!widget.isCorrect)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Correct answer:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.correctAnswer,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFFFFC904),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          // Auto-advance message
                          const Text(
                            'Moving to next question...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFC904),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    '${widget.user.firstName} ${widget.user.lastName.substring(0, 1)}.',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${widget.currentScore}/${widget.totalQuestions}',
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