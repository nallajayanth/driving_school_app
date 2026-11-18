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
        // Stylized automotive gradient icon badge
        Container(
          padding: EdgeInsets.all(compact ? 4 : 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 7 : 10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(37, 99, 235, 0.25),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.electric_car_rounded,
            color: Colors.white,
            size: compact ? 15 : 20,
          ),
        ),
        SizedBox(width: compact ? 5 : 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: compact ? '' : 'FAHRSCHULE ',
                      style: TextStyle(
                        fontSize: compact ? 8 : 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'Powerdrive',
                      style: TextStyle(
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compact)
                const Text(
                  'Austrian Driver Training Platform',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
