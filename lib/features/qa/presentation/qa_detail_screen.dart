import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/qa_post_model.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/presentation/auth_providers.dart';
import 'qa_providers.dart';

class QaDetailScreen extends ConsumerStatefulWidget {
  final QaPostModel post;

  const QaDetailScreen({super.key, required this.post});

  @override
  ConsumerState<QaDetailScreen> createState() => _QaDetailScreenState();
}

class _QaDetailScreenState extends ConsumerState<QaDetailScreen> {
  final _commentController = TextEditingController();
  bool _commentAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(qaControllerProvider.notifier).addComment(
          postId: widget.post.id,
          text: text,
          isAnonymous: _commentAnonymous,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _commentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit comment.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isOwner = widget.post.authorUid != null && widget.post.authorUid == currentUid;
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final isAdmin = userProfile?.isAdmin ?? false;

    final commentsAsync = ref.watch(qaCommentsProvider(widget.post.id));
    final isLikedAsync = ref.watch(isLikedProvider(widget.post.id));
    final isLiked = isLikedAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'delete') {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Delete Question?',
                  message: 'Are you sure you want to delete this post?',
                  isDestructive: true,
                );
                if (confirm) {
                  await ref.read(qaControllerProvider.notifier).deletePost(widget.post);
                  if (context.mounted) Navigator.pop(context);
                }
              } else if (val == 'report') {
                _showReportDialog(context, 'qa_post', widget.post.id);
              }
            },
            itemBuilder: (ctx) => [
              if (isOwner || isAdmin || widget.post.isAnonymous)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Post'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Report Post'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header: Author & Date
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: widget.post.isAnonymous
                          ? Colors.grey.shade400
                          : Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(
                        widget.post.isAnonymous ? Icons.masks_outlined : Icons.person,
                        color: widget.post.isAnonymous
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (widget.post.createdAt != null)
                          Text(
                            DateFormat('MMMM dd, yyyy - hh:mm a')
                                .format(widget.post.createdAt!),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Title
                Text(
                  widget.post.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Question Body
                Text(
                  widget.post.body,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),

                // Optional attached image
                if (widget.post.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Like & Reply counts
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isLiked ? Colors.blue : Colors.grey.shade700,
                        side: BorderSide(
                          color: isLiked ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: () {
                        ref.read(qaControllerProvider.notifier).toggleLike(widget.post.id);
                      },
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 18,
                      ),
                      label: Text('Upvote (${widget.post.likeCount})'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.post.commentCount} Replies',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Comments Section Header
                Text(
                  'Replies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Comments List
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No replies yet. Start the conversation!',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, idx) {
                        final c = comments[idx];
                        final isCommentOwner = c.authorUid == currentUid;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: c.isAnonymous
                                      ? Colors.grey.shade300
                                      : Theme.of(context).primaryColor.withOpacity(0.15),
                                  child: Icon(
                                    c.isAnonymous ? Icons.masks_outlined : Icons.person_outline,
                                    size: 14,
                                    color: c.isAnonymous
                                        ? Colors.grey.shade700
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: c.isAnonymous
                                        ? Colors.grey.shade700
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                if (isCommentOwner || isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                    onPressed: () async {
                                      final confirm = await showConfirmDialog(
                                        context,
                                        title: 'Delete Reply?',
                                        message: 'Are you sure you want to delete this reply?',
                                        isDestructive: true,
                                      );
                                      if (confirm) {
                                        ref.read(qaControllerProvider.notifier).deleteComment(widget.post.id, c);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const LoadingSkeletonList(itemCount: 2, itemHeight: 60),
                  error: (err, _) => Text('Error loading replies: $err'),
                ),
              ],
            ),
          ),

          // Bottom comment input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _commentAnonymous,
                        onChanged: (val) => setState(() => _commentAnonymous = val),
                      ),
                      Text(
                        _commentAnonymous ? 'Reply Anonymously' : 'Public Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: _commentAnonymous ? Colors.blueGrey : Colors.grey.shade700,
                          fontWeight: _commentAnonymous ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Write a reply...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        color: Theme.of(context).primaryColor,
                        onPressed: _isSubmitting ? null : _submitComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, String type, String targetId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Content'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for report',
            hintText: 'Misleading, abusive, or inappropriate...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await ref
                    .read(qaControllerProvider.notifier)
                    .reportContent(type, targetId, reasonController.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.')),
                  );
                }
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
