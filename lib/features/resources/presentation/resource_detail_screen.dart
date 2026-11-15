import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/resource_model.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_providers.dart';
import 'resource_providers.dart';

class ResourceDetailScreen extends ConsumerWidget {
  final ResourceModel resource;

  const ResourceDetailScreen({super.key, required this.resource});

  Future<void> _openAttachment(BuildContext context, ResourceAttachment attachment) async {
    final uri = Uri.tryParse(attachment.url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file URL.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isOwner = currentUid == resource.uploaderUid;
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final isAdmin = userProfile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(resource.courseCode),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'delete') {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Delete Resource?',
                  message: 'Are you sure you want to delete this resource?',
                  isDestructive: true,
                );
                if (confirm) {
                  await ref.read(resourceControllerProvider.notifier).deleteResource(resource.id);
                  if (context.mounted) Navigator.pop(context);
                }
              } else if (val == 'report') {
                _showReportDialog(context, ref);
              }
            },
            itemBuilder: (ctx) => [
              if (isOwner || isAdmin)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Resource'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Report Material'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Course
            Text(
              resource.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${resource.courseCode} - ${resource.courseTitle}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF006A4E), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Semester / Term: ${resource.term}', style: TextStyle(color: Colors.grey.shade700)),
            if (resource.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Uploaded on: ${DateFormat('MMMM dd, yyyy').format(resource.createdAt!)} by ${resource.uploaderName}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Optional Description
            if (resource.description != null && resource.description!.isNotEmpty) ...[
              Text(
                'Description / Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(resource.description!, style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 20),
            ],

            // Attachments Section
            Text(
              'Files & Links (${resource.attachments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            ...resource.attachments.map((att) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _attColor(att.kind).withOpacity(0.15),
                    child: Icon(_attIcon(att.kind), color: _attColor(att.kind)),
                  ),
                  title: Text(att.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    att.kind == 'link'
                        ? 'External Web Link'
                        : att.kind.toUpperCase() + (att.sizeBytes != null ? ' • ${(att.sizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB' : ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _openAttachment(context, att),
                    icon: Icon(att.kind == 'link' ? Icons.open_in_new : Icons.download, size: 16),
                    label: Text(att.kind == 'link' ? 'Open' : 'View'),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _attIcon(String kind) {
    switch (kind) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      default:
        return Icons.link;
    }
  }

  Color _attColor(String kind) {
    switch (kind) {
      case 'pdf':
        return Colors.red.shade700;
      case 'image':
        return Colors.blue.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Resource'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for report',
            hintText: 'Copyright, inaccurate content, spam...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await ref
                    .read(resourceControllerProvider.notifier)
                    .reportResource(resource.id, reasonController.text.trim());
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
