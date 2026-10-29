import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/driving_class.dart';

/// Class selection filter pills and active category header.
class ClassSelectorTabs extends StatelessWidget {
  const ClassSelectorTabs({
    super.key,
    required this.classes,
    required this.selectedClassCode,
    required this.onClassSelected,
  });

  final List<DrivingClass> classes;
  final String selectedClassCode;
  final ValueChanged<String> onClassSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class selection filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: classes.map((drivingClass) {
              final isSelected =
                  drivingClass.code.toUpperCase() ==
                  selectedClassCode.toUpperCase();
              final icon = drivingClass.code.toUpperCase() == 'GW'
                  ? '🧠'
                  : '🚗';
              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.spacingSm),
                child: ChoiceChip(
                  label: Text('$icon Class ${drivingClass.code}'),
                  selected: isSelected,
                  selectedColor: AppColors.primarySubtle,
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTextStyles.label.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusPill,
                    ),
                  ),
                  onSelected: (_) => onClassSelected(drivingClass.code),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Prominent Class Heading matching screenshot (e.g. 🧠 GW)
        Row(
          children: [
            Text(
              selectedClassCode.toUpperCase() == 'GW' ? '🧠' : '🚗',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              selectedClassCode.toUpperCase(),
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
