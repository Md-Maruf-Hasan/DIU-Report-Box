import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/lost_found_model.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_providers.dart';
import 'lost_found_providers.dart';

class LostFoundDetailScreen extends ConsumerWidget {
  final LostFoundModel item;

  const LostFoundDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isOwner = currentUid == item.authorUid;
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final isAdmin = userProfile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.type == 'lost' ? 'Lost Item' : 'Found Item'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'resolve') {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Mark as Resolved?',
                  message: 'This will mark the item as resolved and remove it from the active feed.',
                );
                if (confirm) {
                  await ref.read(lostFoundControllerProvider.notifier).markResolved(item.id);
                  if (context.mounted) Navigator.pop(context);
                }
              } else if (val == 'delete') {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Delete Post?',
                  message: 'Are you sure you want to delete this post? This cannot be undone.',
                  isDestructive: true,
                );
                if (confirm) {
                  await ref.read(lostFoundControllerProvider.notifier).deletePost(item.id);
                  if (context.mounted) Navigator.pop(context);
                }
              } else if (val == 'report') {
                _showReportDialog(context, ref);
              }
            },
            itemBuilder: (ctx) => [
              if (isOwner && !item.isResolved)
                const PopupMenuItem(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark Resolved'),
                    ],
                  ),
                ),
              if (isOwner || isAdmin)
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
              if (!isOwner)
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Images Gallery
            if (item.imageUrls.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: item.imageUrls.length,
                  itemBuilder: (context, idx) {
                    return Image.network(
                      item.imageUrls[idx],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge and Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.type == 'lost' ? Colors.red.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            color: item.type == 'lost' ? Colors.red.shade900 : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(item.category),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (item.isResolved) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Resolved', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.blueGrey,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Date and location
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(item.date),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Contact Note / Info
                  if (item.contact != null && item.contact!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.contact_mail_outlined, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Contact Information',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(item.contact!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Poster attribution
                  Text(
                    'Posted by: ${item.authorName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Post'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for reporting',
            hintText: 'Spam, inappropriate content, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await ref
                    .read(lostFoundControllerProvider.notifier)
                    .reportContent(item.id, reasonController.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted for moderation.')),
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
