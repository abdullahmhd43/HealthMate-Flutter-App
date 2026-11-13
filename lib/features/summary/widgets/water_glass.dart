import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// A glass that fills with water. [progress] is a fraction where 1.0 is full;
/// the glass is capped at full when the target is beaten.
class WaterGlass extends StatelessWidget {
  const WaterGlass({
    super.key,
    required this.progress,
    this.width = 104,
    this.height = 200,
  });

  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0).toDouble();
    const bottomRadius = 30.0;
    const topRadius = 12.0;
    const border = 3.0;

    return Semantics(
      label: 'Water level ${(target * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, level, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.water.withValues(alpha: 0.55),
                width: border,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(topRadius),
                topRight: Radius.circular(topRadius),
                bottomLeft: Radius.circular(bottomRadius),
                bottomRight: Radius.circular(bottomRadius),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(topRadius - border),
                topRight: Radius.circular(topRadius - border),
                bottomLeft: Radius.circular(bottomRadius - border),
                bottomRight: Radius.circular(bottomRadius - border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: level,
                      widthFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF64B5F6), AppColors.water],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(level * 100).round()}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: level > 0.55
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
