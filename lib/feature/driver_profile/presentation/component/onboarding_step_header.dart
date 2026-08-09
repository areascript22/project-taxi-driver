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
    final colorScheme = Theme.of(context).colorScheme;

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
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.1),
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
            color: colorScheme.primary.withValues(alpha: 0.9),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
