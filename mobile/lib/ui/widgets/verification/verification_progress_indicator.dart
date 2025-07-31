
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class VerificationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;

  const VerificationProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Indicateurs circulaires avec ligne de progression
          Row(
            children: [
              for (int i = 0; i < totalSteps; i++) ...[
                // Cercle d'étape
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i <= currentStep 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: i < currentStep
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i <= currentStep ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                
                // Ligne de connexion (sauf pour le dernier)
                if (i < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: i < currentStep 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          
          // Labels des étapes si fournis
          if (stepLabels != null && stepLabels!.length == totalSteps) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < totalSteps; i++) ...[
                  Expanded(
                    child: Text(
                      stepLabels![i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == currentStep ? FontWeight.w600 : FontWeight.normal,
                        color: i <= currentStep 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}