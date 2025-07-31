
import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatelessWidget {
  final int timeRemaining;
  final VoidCallback? onResendPressed;
  final bool canResend;
  final bool isLoading;

  const CountdownTimerWidget({
    Key? key,
    required this.timeRemaining,
    this.onResendPressed,
    required this.canResend,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timeRemaining > 0) ...[
          Icon(
            Icons.access_time,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            'Code expire dans ${_formatTime(timeRemaining)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ] else if (canResend) ...[
          const Text(
            'Code expiré ? ',
            style: TextStyle(fontSize: 14),
          ),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: onResendPressed,
              child: const Text(
                'Renvoyer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
