import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/constants.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'lost_found_providers.dart';

class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(lostFoundFilterProvider);
    final feedAsync = ref.watch(lostFoundFeedProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search lost & found...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                ref.read(lostFoundFilterProvider.notifier).state =
                    filters.copyWith(searchQuery: val);
              },
            ),
          ),

          // Filter Chips: All, Lost, Found, Resolved
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All Items',
                  isSelected: filters.typeFilter == 'all',
                  onSelected: () => ref
                      .read(lostFoundFilterProvider.notifier)
                      .state = filters.copyWith(typeFilter: 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Lost',
                  isSelected: filters.typeFilter == 'lost',
                  onSelected: () => ref
                      .read(lostFoundFilterProvider.notifier)
                      .state = filters.copyWith(typeFilter: 'lost'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Found',
                  isSelected: filters.typeFilter == 'found',
                  onSelected: () => ref
                      .read(lostFoundFilterProvider.notifier)
                      .state = filters.copyWith(typeFilter: 'found'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Resolved',
                  isSelected: filters.typeFilter == 'resolved',
                  onSelected: () => ref
                      .read(lostFoundFilterProvider.notifier)
                      .state = filters.copyWith(typeFilter: 'resolved'),
                ),
              ],
            ),
          ),

          // Category filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                ActionChip(
                  label: Text(filters.categoryFilter == 'all'
                      ? 'Category: All'
                      : 'Category: ${filters.categoryFilter}'),
                  avatar: const Icon(Icons.tune, size: 16),
                  onPressed: () => _showCategoryPicker(context, ref, filters),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main List View
          Expanded(
            child: feedAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No items found',
                    subtitle: filters.searchQuery.isNotEmpty
                        ? 'Try searching with a different term or clear filters.'
                        : 'No items reported in this category yet.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(lostFoundFeedProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isLost = item.type == 'lost';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: AppConstants.demoPreview
                              ? null
                              : () => context.push('/lost-found/${item.id}',
                                  extra: item),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.imageUrls.isNotEmpty
                                      ? Image.network(
                                          item.imageUrls.first,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholderBox(),
                                        )
                                      : _placeholderBox(),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isLost
                                                  ? Colors.red.shade100
                                                  : Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isLost ? 'LOST' : 'FOUND',
                                              style: TextStyle(
                                                color: isLost
                                                    ? Colors.red.shade900
                                                    : Colors.green.shade900,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (item.isResolved)
                                            const Chip(
                                              label: Text('Resolved',
                                                  style:
                                                      TextStyle(fontSize: 10)),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              backgroundColor: Colors.blueGrey,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined,
                                              size: 14,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(item.date),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingSkeletonList(itemCount: 4),
              error: (err, _) => ErrorRetryView(
                message: err.toString(),
                onRetry: () => ref.invalidate(lostFoundFeedProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lost-found-create',
        onPressed: AppConstants.demoPreview
            ? null
            : () => context.push('/lost-found/create'),
        icon: const Icon(Icons.add),
        label: const Text('Post Item'),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  void _showCategoryPicker(
      BuildContext context, WidgetRef ref, LostFoundFilterState filters) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Categories'),
              trailing: filters.categoryFilter == 'all'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref.read(lostFoundFilterProvider.notifier).state =
                    filters.copyWith(categoryFilter: 'all');
                Navigator.pop(ctx);
              },
            ),
            ...AppConstants.lostFoundCategories.map((cat) {
              final isSel = filters.categoryFilter == cat;
              return ListTile(
                title: Text(cat),
                trailing:
                    isSel ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(lostFoundFilterProvider.notifier).state =
                      filters.copyWith(categoryFilter: cat);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
