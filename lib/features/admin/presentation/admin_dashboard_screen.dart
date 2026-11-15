import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/report_model.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/presentation/auth_providers.dart';
import 'admin_providers.dart';
import 'manage_contacts_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Center'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.build), text: 'Reports'),
            Tab(icon: Icon(Icons.flag), text: 'Moderation'),
            Tab(icon: Icon(Icons.contact_phone), text: 'Contacts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminReportsTab(),
          _AdminModerationTab(),
          ManageContactsScreen(),
        ],
      ),
    );
  }
}

class _AdminReportsTab extends ConsumerWidget {
  const _AdminReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsProvider);

    return Column(
      children: [
        // Action Bar for SMS Retry
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              const Icon(Icons.sms_failed_outlined, color: Colors.brown, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Retry pending/failed SMS to maintenance staff',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () async {
                  try {
                    final count = await ref.read(adminRepositoryProvider).retryFailedSms();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Retried SMS for $count reports.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Retry failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Retry Now', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),

        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              if (reports.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.done_all,
                  title: 'No maintenance reports',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (context, idx) {
                  final r = reports[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r.refNo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              _StatusDropdown(report: r),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Dept: ${r.departmentId.toUpperCase()} • Room: ${r.roomNo} • Category: ${r.category}',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(r.description, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                r.smsStatus == 'sent' ? Icons.check_circle : Icons.error_outline,
                                size: 14,
                                color: r.smsStatus == 'sent' ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text('SMS: ${r.smsStatus.toUpperCase()} (Attempts: ${r.smsAttempts})',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              const Spacer(),
                              if (r.createdAt != null)
                                Text(DateFormat('MMM dd, hh:mm a').format(r.createdAt!),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingSkeletonList(itemCount: 4),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _StatusDropdown extends ConsumerWidget {
  final ReportModel report;

  const _StatusDropdown({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final adminUid = userProfile?.uid ?? 'admin';
    final adminName = userProfile?.name ?? 'Admin';

    return DropdownButton<String>(
      value: report.status,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
        DropdownMenuItem(value: 'sms_sent', child: Text('SMS Sent')),
        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
      ],
      onChanged: (newStatus) async {
        if (newStatus != null && newStatus != report.status) {
          final noteController = TextEditingController();
          final addNote = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Change Status to ${newStatus.toUpperCase()}'),
              content: TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Staff note to student (Optional)',
                  hintText: 'e.g. Technician dispatched / Power supply replaced',
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
              ],
            ),
          );

          if (addNote == true) {
            await ref.read(adminRepositoryProvider).updateReportStatus(
                  reportId: report.id,
                  newStatus: newStatus,
                  adminUid: adminUid,
                  adminName: adminName,
                  noteText: noteController.text.trim(),
                );
          }
        }
      },
    );
  }
}

class _AdminModerationTab extends ConsumerWidget {
  const _AdminModerationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(moderationQueueProvider);

    return queueAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const EmptyStateView(
            icon: Icons.verified_user_outlined,
            title: 'Moderation queue is clean',
            subtitle: 'No flagged or reported content pending review.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          itemBuilder: (context, idx) {
            final r = reports[idx];
            final id = r['id'] as String;
            final targetType = r['targetType'] as String? ?? 'Content';
            final targetId = r['targetId'] as String? ?? '';
            final reason = r['reason'] as String? ?? 'No reason';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(targetType.toUpperCase()),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.red.shade100,
                        ),
                        const SizedBox(width: 8),
                        Text('Target ID: ${targetId.substring(0, targetId.length > 8 ? 8 : targetId.length)}...'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Reason reported: "$reason"',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ref
                                .read(adminRepositoryProvider)
                                .resolveModerationReport(id, false, targetType, targetId);
                          },
                          child: const Text('Dismiss Report'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            ref
                                .read(adminRepositoryProvider)
                                .resolveModerationReport(id, true, targetType, targetId);
                          },
                          child: const Text('Delete Content'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingSkeletonList(itemCount: 3),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
