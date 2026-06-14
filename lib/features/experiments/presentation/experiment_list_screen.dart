import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/experiment_card.dart';
import '../../../shared/models/experiment_model.dart';
import '../providers/experiment_provider.dart';

class ExperimentListScreen extends ConsumerWidget {
  final bool analyticsMode;

  const ExperimentListScreen({
    super.key,
    this.analyticsMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final filtered = ref.watch(filteredExperimentsProvider);
    final currentFilter = ref.watch(experimentFilterProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(analyticsMode ? 'Chọn thí nghiệm để xem thống kê' : 'Experiments'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context, ref),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: currentFilter.status == null,
                    onTap: () => ref.read(experimentFilterProvider.notifier).state =
                        const ExperimentFilter(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Draft',
                    isSelected: currentFilter.status == ExperimentStatus.draft,
                    onTap: () => ref.read(experimentFilterProvider.notifier).state =
                        ExperimentFilter(status: ExperimentStatus.draft),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Pending',
                    isSelected: currentFilter.status == ExperimentStatus.pending,
                    onTap: () => ref.read(experimentFilterProvider.notifier).state =
                        ExperimentFilter(status: ExperimentStatus.pending),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Active',
                    isSelected: currentFilter.status == ExperimentStatus.active,
                    onTap: () => ref.read(experimentFilterProvider.notifier).state =
                        ExperimentFilter(status: ExperimentStatus.active),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Completed',
                    isSelected: currentFilter.status == ExperimentStatus.completed,
                    onTap: () => ref.read(experimentFilterProvider.notifier).state =
                        ExperimentFilter(status: ExperimentStatus.completed),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: filtered.when(
              data: (exps) {
                if (exps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science_outlined, size: 64, color: cs.onSurface.withAlpha(51)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No experiments found',
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface.withAlpha(128),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/experiments/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Experiment'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: exps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final exp = exps[index];
                    return ExperimentCard(
                      title: exp.title,
                      status: exp.status,
                      startDate: exp.startDate,
                      zone: exp.cropVariety,
                      progress: exp.progress,
                      studentCount: 2,
                      experimentCode: exp.experimentCode,
                      onTap: analyticsMode
                          ? () => context.push('/experiments/${exp.id}?analytics=true')
                          : () => context.push('/experiments/${exp.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: analyticsMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/experiments/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: ref.read(experimentFilterProvider).searchQuery ?? '',
        );
        return AlertDialog(
          title: const Text('Search Experiments'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title, code, or crop...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final current = ref.read(experimentFilterProvider);
                ref.read(experimentFilterProvider.notifier).state = ExperimentFilter(
                  status: current.status,
                  searchQuery: controller.text,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(30)
              : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withAlpha(102)
                : cs.outline.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? AppColors.primary : cs.onSurface.withAlpha(153),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
