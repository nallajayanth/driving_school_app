import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Clean brand logo component for Powerdrive Learning.
/// Displays the official SmartDrive graduation cap & automotive logo.
/// Responsive and overflow-safe across small and large screens.
class PowerdriveLogo extends StatelessWidget {
  const PowerdriveLogo({
    super.key,
    this.compact = false,
    this.size,
  });

  final bool compact;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double logoSize = size ?? (compact ? 28.0 : 38.0);
    final double borderRadiusVal = compact ? 7.0 : 10.0;

    final logoWidget = Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 185, 129, 0.20),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.06),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadiusVal),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(borderRadiusVal),
            ),
            child: Icon(
              Icons.electric_car_rounded,
              color: Colors.white,
              size: logoSize * 0.6,
            ),
          ),
        ),
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logoWidget,
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Powerdrive',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(width: 10),
        Flexible(
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
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'Powerdrive',
                      style: TextStyle(
                        fontSize: 16,
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
              const Text(
                'Austrian Driver Training Platform',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
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
