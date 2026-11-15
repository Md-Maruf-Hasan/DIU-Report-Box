import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'report_providers.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const EmptyStateView(
            icon: Icons.assignment_outlined,
            title: 'No maintenance reports yet',
            subtitle: 'Any campus maintenance report you submit will appear here with live status updates.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myReportsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(report.status).withOpacity(0.15),
                    child: Icon(
                      _statusIcon(report.status),
                      color: _statusColor(report.status),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        report.refNo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(report.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(report.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Room ${report.roomNo} • ${report.category}'),
                      const SizedBox(height: 2),
                      Text(
                        report.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (report.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy - hh:mm a').format(report.createdAt!),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/report/${report.id}', extra: report),
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingSkeletonList(itemCount: 4),
      error: (e, _) => ErrorRetryView(
        message: e.toString(),
        onRetry: () => ref.invalidate(myReportsProvider),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'sms_sent':
        return Colors.amber.shade800;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.send;
      case 'sms_sent':
        return Icons.sms_outlined;
      case 'in_progress':
        return Icons.build_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
