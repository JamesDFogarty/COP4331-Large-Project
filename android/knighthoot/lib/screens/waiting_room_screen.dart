import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/quiz_session.dart';
import '../services/quiz_services.dart';
import 'quiz_question_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final User user;
  final QuizSession session;

  const WaitingRoomScreen({
    Key? key,
    required this.user,
    required this.session,
  }) : super(key: key);

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  Timer? _pollTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isChecking) return;

      setState(() => _isChecking = true);

      try {
        final updatedSession = await QuizService.getQuizStatus(
          widget.session.testID,
          widget.user.token ?? '',  // Added token
        );
        
        if (updatedSession.isLive && updatedSession.currentQuestion >= 0) {
          _pollTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QuizQuestionScreen(
                  user: widget.user,
                  session: updatedSession,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error polling: $e');
      } finally {
        if (mounted) setState(() => _isChecking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room', style: TextStyle(color: Color(0xFFFFD700))),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Icon(
                      Icons.hourglass_empty,
                      size: 100,
                      color: Color(0xFFFFD700).withOpacity(value),
                    ),
                  );
                },
                onEnd: () {
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 32),

              Text(
                widget.session.testName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              const Text(
                'Waiting for teacher to start...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.user.firstName} ${widget.user.lastName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quiz Code: ${widget.session.testID}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}