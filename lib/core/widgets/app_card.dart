import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Reusable modern card component for Powerdrive screens.
/// Features a crisp white background, subtle refined border, rounded corners, and smooth click ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.spacingBase),
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor = AppColors.surface,
    this.borderRadius = AppConstants.radiusLg,
    this.gradient,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color backgroundColor;
  final double borderRadius;
  final Gradient? gradient;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: elevation > 0 ? 12 : 6,
            offset: Offset(0, elevation > 0 ? 4 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
