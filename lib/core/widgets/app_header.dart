import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'powerdrive_logo.dart';

/// Reusable top navigation and branding header for the mobile app.
/// Responsive and overflow-protected across all phone widths.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.selectedLanguage = 'DE',
    this.onLanguageChanged,
    this.onLogout,
  });

  final String selectedLanguage;
  final ValueChanged<String>? onLanguageChanged;
  final VoidCallback? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          child: Row(
            children: [
              // Flexible Brand Logo
              const Expanded(child: PowerdriveLogo(compact: true)),
              const SizedBox(width: 4),

              // Language Selector Dropdown Pill
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'DE',
                        child: Text('DE DE'),
                      ),
                      DropdownMenuItem(
                        value: 'EN',
                        child: Text('EN EN'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null && onLanguageChanged != null) {
                        onLanguageChanged!(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Logout Button Pill
              Material(
                color: AppColors.logoutBackground,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                child: InkWell(
                  onTap:
                      onLogout ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Log out triggered')),
                        );
                      },
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          size: 13,
                          color: AppColors.logout,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Log out',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.logout,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
