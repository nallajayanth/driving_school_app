import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/learning_unit.dart';
import 'learning_providers.dart';
import 'widgets/class_selector_tabs.dart';
import 'widgets/learning_unit_card.dart';
import 'widgets/question_search_bar.dart';

/// Mobile-first Learning Overview Screen replicating the Powerdrive Learning layout.
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  bool _isSearching = false;

  Future<void> _handleQuestionSearch(int questionNumber) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final repo = ref.read(learningRepositoryProvider);
      final question = await repo.getQuestionByNumber(questionNumber);

      if (!mounted) return;

      if (question != null) {
        context.push('/learning/question/$questionNumber');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Question #$questionNumber was not found in the catalog.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedLearningClassProvider);
    final classesAsync = ref.watch(drivingClassesProvider);
    final unitsAsync = ref.watch(learningUnitsProvider(selectedClass));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(drivingClassesProvider);
        ref.invalidate(learningUnitsProvider(selectedClass));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingBase,
          vertical: AppConstants.spacingBase,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dev / Mock Notice Pill
            _buildMockDataBanner(),
            const SizedBox(height: AppConstants.spacingMd),

            // Header and Question Search Box
            AppCard(
              padding: const EdgeInsets.all(AppConstants.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  Row(
                    children: [
                      const Text('📘', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          'Your learning units at a glance',
                          style: AppTextStyles.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingBase),

                  // Question search bar
                  QuestionSearchBar(
                    isLoading: _isSearching,
                    onSearch: _handleQuestionSearch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Class selector tabs (GW, B)
            classesAsync.when(
              data: (classes) => ClassSelectorTabs(
                classes: classes,
                selectedClassCode: selectedClass,
                onClassSelected: (code) {
                  ref
                      .read(selectedLearningClassProvider.notifier)
                      .selectClass(code);
                },
              ),
              loading: () => const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Failed to load classes: $e'),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Learning Units List
            unitsAsync.when(
              data: (units) => _buildUnitsList(context, units),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              error: (err, _) => _buildErrorCard(selectedClass, err.toString()),
            ),
            const SizedBox(height: AppConstants.spacing2xl),
          ],
        ),
      ),
    );
  }

  Widget _buildMockDataBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Development Mode · Local Mock Data',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(BuildContext context, List<LearningUnit> units) {
    if (units.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                'No learning units available for this class',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: units.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingBase),
      itemBuilder: (context, index) {
        final unit = units[index];
        return LearningUnitCard(
          unit: unit,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected topic: ${unit.title}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorCard(String currentClass, String error) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingBase),
      decoration: BoxDecoration(
        color: AppColors.logoutBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load learning units',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(learningUnitsProvider(currentClass));
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
