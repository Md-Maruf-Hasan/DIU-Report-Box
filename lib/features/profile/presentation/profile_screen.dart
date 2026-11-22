import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
      ),
      body: userProfileAsync.when(
        data: (profile) {
          final name = profile?.name ?? user?.displayName ?? 'Student';
          final email = profile?.email ?? user?.email ?? '';
          final dept = profile?.departmentId.toUpperCase() ?? 'DIU';
          final studentId = profile?.studentId ?? 'Not specified';
          final isAdmin = profile?.isAdmin ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar & Name Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(isAdmin ? 'Administrator' : 'Verified Student'),
                          backgroundColor: isAdmin ? Colors.amber.shade100 : Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: isAdmin ? Colors.amber.shade900 : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Student Academic Info
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: const Text('Department'),
                        subtitle: Text(dept),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Student ID'),
                        subtitle: Text(studentId),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Account actions
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset_outlined),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/forgot-password');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            title: 'Sign Out?',
                            message: 'Are you sure you want to log out of DIU Report Box?',
                          );
                          if (confirm) {
                            await ref.read(authControllerProvider.notifier).signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'DIU Report Box v1.0.0\nDaffodil International University',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
