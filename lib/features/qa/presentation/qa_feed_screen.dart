import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/constants.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'qa_providers.dart';

class QaFeedScreen extends ConsumerWidget {
  const QaFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(qaFilterProvider);
    final feedAsync = ref.watch(qaFeedProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search questions & discussions...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(qaFilterProvider.notifier).state =
                          filters.copyWith(searchQuery: val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort by',
                  onSelected: (val) {
                    ref.read(qaFilterProvider.notifier).state =
                        filters.copyWith(sortBy: val);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'newest',
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              color: filters.sortBy == 'newest' ? Colors.green : null),
                          const SizedBox(width: 8),
                          const Text('Newest'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'active',
                      child: Row(
                        children: [
                          Icon(Icons.whatshot,
                              color: filters.sortBy == 'active' ? Colors.green : null),
                          const SizedBox(width: 8),
                          const Text('Most Active'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Feed
          Expanded(
            child: feedAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.question_answer_outlined,
                    title: 'No discussions yet',
                    subtitle: filters.searchQuery.isNotEmpty
                        ? 'Try a different search keyword.'
                        : 'Be the first student to ask a question!',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(qaFeedProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: AppConstants.demoPreview
                              ? null
                              : () => context.push('/qa/${post.id}', extra: post),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Author & timestamp
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: post.isAnonymous
                                          ? Colors.grey.shade400
                                          : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                      child: Icon(
                                        post.isAnonymous
                                            ? Icons.masks_outlined
                                            : Icons.person_outline,
                                        size: 16,
                                        color: post.isAnonymous
                                            ? Colors.white
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      post.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: post.isAnonymous
                                            ? Colors.grey.shade700
                                            : Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (post.isAnonymous) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Anon',
                                            style: TextStyle(fontSize: 10)),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (post.createdAt != null)
                                      Text(
                                        DateFormat('MMM dd').format(post.createdAt!),
                                        style: TextStyle(
                                            color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Title
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Body snippet
                                Text(
                                  post.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Footer: likes & comments count
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up_alt_outlined,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount}'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.comment_outlined,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text('${post.commentCount} replies'),
                                    const Spacer(),
                                    if (post.imageUrl != null)
                                      const Icon(Icons.image_outlined,
                                          size: 16, color: Colors.blueGrey),
                                  ],
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
                onRetry: () => ref.invalidate(qaFeedProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'qa-create',
        onPressed: AppConstants.demoPreview ? null : () => context.push('/qa/create'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Ask / Post'),
      ),
    );
  }
}
