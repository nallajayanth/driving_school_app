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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'DEVELOPMENT PREVIEW · PRELIMINARY CHECK',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingBase),

                  // Title and instructions
                  Text('Start preliminary check', style: AppTextStyles.h1),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    'Choose one or more examination classes to begin your preliminary driving theory test.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
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

                  const SizedBox(height: AppConstants.spacingBase),

                  // Total questions calculation card
                  AppCard(
                    backgroundColor: AppColors.surfaceVariant,
                    borderColor: AppColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
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
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total: ${selectionState.totalQuestions} questions including bonus questions',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectionState.selectedClassCodes.isEmpty
                                        ? 'Select at least one class above'
                                        : 'Selected: ${selectionState.selectedClassCodes.join(", ")}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        const Divider(height: 1),
                        const SizedBox(height: AppConstants.spacingSm),
                        Text(
                          'Note: The combined GW + B examination rule requires backend confirmation. Total is computed from current repository configuration.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
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
    final iconEmoji = dClass.code == 'GW' ? '🧠' : '🚗';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      backgroundColor: isSelected ? AppColors.primarySubtle : AppColors.surface,
      child: Row(
        children: [
          // Emoji badge
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Text(iconEmoji, style: const TextStyle(fontSize: 22)),
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
                  ),
                ),
                if (dClass.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    dClass.description!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Checkbox / Radio indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
