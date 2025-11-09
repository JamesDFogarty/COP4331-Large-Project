import 'package:flutter/material.dart';
import 'dart:async';

class AnswerFeedbackScreen extends StatefulWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String studentAnswer;

  const AnswerFeedbackScreen({
    Key? key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.studentAnswer,
  }) : super(key: key);

  @override
  State<AnswerFeedbackScreen> createState() => _AnswerFeedbackScreenState();
}

class _AnswerFeedbackScreenState extends State<AnswerFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-advance after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context, true); // Return true to continue
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isCorrect 
          ? const Color(0xFF1B5E20) // Dark green
          : const Color(0xFFB71C1C), // Dark red
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),
                
                Text(
                  widget.isCorrect ? 'Correct!' : 'Incorrect',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Your answer: ',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            widget.studentAnswer,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (!widget.isCorrect) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Correct answer: ',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              widget.correctAnswer,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                const Text(
                  'Moving to next question...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}