import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../exam_history/presentation/exam_providers.dart';
import '../../learning/domain/driving_class.dart';

/// Screen allowing the learner to choose examination classes (e.g. GW, B)
/// and launch a preliminary assessment.
class PreliminaryCheckScreen extends ConsumerWidget {
  const PreliminaryCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibleClassesAsync = ref.watch(eligibleExamClassesProvider);
    final selectionState = ref.watch(preliminarySelectionProvider);

    return Scaffold(
      body: SafeArea(
        child: eligibleClassesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingBase),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppConstants.spacingBase),
                  Text(
                    'Unable to load examination classes',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppConstants.spacingBase),
                  AppButton(
                    label: 'Retry',
                    isFullWidth: false,
                    onPressed: () =>
                        ref.invalidate(eligibleExamClassesProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (availableClasses) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Development/Mock badge
                  Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusPill,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.speed_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'OFFICIAL POWERDRIVE EXAM',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingBase),

                  // Title and instructions
                  Text(
                    'Start preliminary check',
                    style: AppTextStyles.h1.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose one or more examination classes to begin your preliminary driving theory test.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Class selection heading
                  Text('Available Driving Classes', style: AppTextStyles.h3),
                  const SizedBox(height: AppConstants.spacingSm),

                  // Class items
                  ...availableClasses.map((dClass) {
                    final isSelected = selectionState.selectedClassCodes
                        .contains(dClass.code);

                    return _buildClassOptionCard(
                      context: context,
                      dClass: dClass,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(preliminarySelectionProvider.notifier)
                            .toggleClass(dClass.code, availableClasses);
                      },
                    );
                  }),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Total questions calculation card
                  AppCard(
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.format_list_numbered_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total: ${selectionState.totalQuestions} questions including bonus questions',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectionState.selectedClassCodes.isEmpty
                                        ? 'Select at least one class above'
                                        : 'Selected: ${selectionState.selectedClassCodes.join(", ")}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: AppConstants.spacingSm),
                        Text(
                          'Note: The combined GW + B examination rule requires backend confirmation. Total is computed from current repository configuration.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Start Preliminary Check primary button
                  AppButton(
                    label: 'Start preliminary check',
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    onPressed: selectionState.canStart
                        ? () async {
                            final selectedList = selectionState
                                .selectedClassCodes
                                .toList();
                            await ref
                                .read(examSessionProvider.notifier)
                                .startSession(selectedList);
                            if (context.mounted) {
                              context.go('/exam-session');
                            }
                          }
                        : null,
                  ),

                  const SizedBox(height: AppConstants.spacingXl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassOptionCard({
    required BuildContext context,
    required DrivingClass dClass,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isGw = dClass.code == 'GW';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      backgroundColor: isSelected ? AppColors.primarySubtle : AppColors.surface,
      child: Row(
        children: [
          // Styled Icon badge
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Icon(
              isGw ? Icons.psychology_rounded : Icons.directions_car_rounded,
              size: 22,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spacingBase),

          // Title and question count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dClass.code} — ${dClass.preliminaryExamQuestionsCount} questions',
                  style: AppTextStyles.h3.copyWith(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (dClass.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    dClass.description!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Checkbox indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.textInverse,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
