import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Clean brand logo component for Powerdrive Learning.
/// Responsive and overflow-safe across small and large screens.
class PowerdriveLogo extends StatelessWidget {
  const PowerdriveLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Stylized car speed icon
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'FAHRSCHULE ',
                      style: TextStyle(
                        fontSize: compact ? 8.5 : 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Powerdrive',
                      style: TextStyle(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compact)
                Text(
                  'www.powerdrive.at',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
