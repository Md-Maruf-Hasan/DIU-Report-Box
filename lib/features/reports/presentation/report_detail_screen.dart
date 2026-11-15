import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/report_model.dart';
import 'report_providers.dart';

class ReportDetailScreen extends ConsumerWidget {
  final ReportModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(reportNotesProvider(report.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${report.refNo}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Card(
              color: _statusBgColor(report.status),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(report.status),
                      size: 36,
                      color: _statusTextColor(report.status),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${report.status.replaceAll('_', ' ').toUpperCase()}',
                            style: TextStyle(
                              color: _statusTextColor(report.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusDescription(report.status),
                            style: TextStyle(
                              color: _statusTextColor(report.status).withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _infoRow('Reference No', report.refNo),
                    _infoRow('Room / Lab', 'Room ${report.roomNo}'),
                    _infoRow('Category', report.category),
                    if (report.createdAt != null)
                      _infoRow(
                        'Submitted At',
                        DateFormat('MMM dd, yyyy - hh:mm a').format(report.createdAt!),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attached Photos
            if (report.imageUrls.isNotEmpty) ...[
              Text(
                'Attached Evidence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.imageUrls.length,
                  itemBuilder: (context, idx) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(report.imageUrls[idx]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Maintenance / Admin Notes Timeline
            Text(
              'Maintenance Updates & Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No staff notes added yet. Updates will appear here as technicians work on your report.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final note = notes[idx];
                    return Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  note.byName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                if (note.createdAt != null)
                                  Text(
                                    DateFormat('MMM dd, hh:mm a').format(note.createdAt!),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(note.text, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading updates: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue.shade50;
      case 'sms_sent':
        return Colors.amber.shade50;
      case 'in_progress':
        return Colors.orange.shade50;
      case 'resolved':
        return Colors.green.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue.shade900;
      case 'sms_sent':
        return Colors.amber.shade900;
      case 'in_progress':
        return Colors.orange.shade900;
      case 'resolved':
        return Colors.green.shade900;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.grey.shade800;
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

  String _statusDescription(String status) {
    switch (status) {
      case 'submitted':
        return 'Your report has been received and queued for dispatch.';
      case 'sms_sent':
        return 'SMS alert successfully sent to department maintenance staff.';
      case 'in_progress':
        return 'Staff has acknowledged the report and is currently working on it.';
      case 'resolved':
        return 'The reported issue has been addressed and marked resolved.';
      case 'rejected':
        return 'This report could not be processed.';
      default:
        return 'Report status pending.';
    }
  }
}
