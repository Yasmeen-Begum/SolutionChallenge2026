import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/incident.dart';

/// Severity badge pill with colour coding and icon.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge(this.severity, {super.key, this.small = false});

  final IncidentSeverity severity;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSeverity(severity.name);
    final size  = small ? 11.0 : 12.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(severity.emoji, style: TextStyle(fontSize: size - 1)),
          const SizedBox(width: 4),
          Text(
            severity.label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: size,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing dot for active crisis indicators.
class PulseIndicator extends StatelessWidget {
  const PulseIndicator({super.key, required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size * 2.4,
          height: size * 2.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.2, 1.2),
              duration: 1200.ms,
              curve: Curves.easeInOut,
            ).then().scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.6, 0.6),
              duration: 1200.ms,
            ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

/// Status badge for incident/personnel status.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}
