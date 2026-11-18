import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// Brand action button supporting primary blue styling, icons, and loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.textInverse;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.primarySubtle;
        foregroundColor = AppColors.primary;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.border, width: 1.5);
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.logoutBackground;
        foregroundColor = AppColors.logout;
        borderSide = const BorderSide(color: Color(0xFFFCA5A5), width: 1);
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppConstants.spacingSm),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: isEnabled ? foregroundColor : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? backgroundColor : AppColors.borderSubtle,
      foregroundColor: foregroundColor,
      elevation: variant == AppButtonVariant.primary && isEnabled ? 1 : 0,
      shadowColor: const Color.fromRGBO(37, 99, 235, 0.25),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: borderSide ?? BorderSide.none,
      ),
      minimumSize: const Size(0, AppConstants.minTouchTarget),
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isEnabled ? onPressed : null,
        child: content,
      ),
    );
  }
}
