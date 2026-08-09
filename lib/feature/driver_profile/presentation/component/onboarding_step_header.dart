import 'package:flutter/material.dart';

class OnboardingStepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;

  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index < step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? const Color(0xFFE94560)
                          : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Text(
          'Paso $step de $totalSteps',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE94560).withOpacity(0.9),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }
}
