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
              final isGw = drivingClass.code.toUpperCase() == 'GW';

              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.spacingSm),
                child: ChoiceChip(
                  avatar: Icon(
                    isGw ? Icons.psychology_rounded : Icons.directions_car_rounded,
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: Text('Class ${drivingClass.code}'),
                  selected: isSelected,
                  selectedColor: AppColors.primarySubtle,
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTextStyles.label.copyWith(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  onSelected: (_) => onClassSelected(drivingClass.code),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Prominent Class Heading banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selectedClassCode.toUpperCase() == 'GW'
                      ? Icons.menu_book_rounded
                      : Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedClassCode.toUpperCase(),
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      selectedClassCode.toUpperCase() == 'GW'
                          ? 'Austrian General Driving Knowledge (Grundwissen)'
                          : 'Austrian Class B Passenger Car Theory',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
