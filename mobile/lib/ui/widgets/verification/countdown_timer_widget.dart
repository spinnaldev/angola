import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimerWidget extends StatefulWidget {
  final int timeRemaining; // en secondes
  final bool canResend;
  final bool isLoading;
  final VoidCallback onResendPressed;

  const CountdownTimerWidget({
    Key? key,
    required this.timeRemaining,
    required this.canResend,
    required this.isLoading,
    required this.onResendPressed,
  }) : super(key: key);

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.timeRemaining;
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeRemaining != oldWidget.timeRemaining) {
      _secondsRemaining = widget.timeRemaining;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    
    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canShowResend = widget.canResend || _secondsRemaining <= 0;
    
    return Column(
      children: [
        if (!canShowResend) ...[
          // Affichage du timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 6),
                Text(
                  'Renvoyer dans ${_formatTime(_secondsRemaining)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Bouton renvoyer
          TextButton.icon(
            onPressed: widget.isLoading ? null : widget.onResendPressed,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: Text(
              widget.isLoading ? 'Envoi...' : 'Renvoyer le code',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Informations supplémentaires
        Text(
          canShowResend 
              ? 'Vous n\'avez pas reçu le code ?'
              : 'Un nouveau code peut être demandé dans quelques secondes',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}