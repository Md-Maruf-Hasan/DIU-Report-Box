import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/demo_mode.dart';
import '../../../app/theme.dart';
import '../../../core/models/user_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reports/presentation/report_providers.dart';
import '../../resources/presentation/resource_providers.dart';

const _profileBlue = Color(0xFF0783C4);
const _profileTeal = Color(0xFF05A0B5);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(demoModeProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final user =
        isDemoMode ? null : ref.watch(authRepositoryProvider).currentUser;
    final reportCount =
        ref.watch(myReportsProvider).whenData((reports) => reports.length);
    final resourceCount = ref
        .watch(myResourcesProvider)
        .whenData((resources) => resources.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: _profileBlue,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        data: (profile) {
          final name = profile?.name ?? user?.displayName ?? 'Student';
          final email = profile?.email ?? user?.email ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      profile: profile,
                      name: name,
                      email: email,
                      isAdmin: profile?.isAdmin ?? false,
                      onEdit: () {
                        if (isDemoMode) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Profile editing is unavailable in demo preview.',
                              ),
                            ),
                          );
                          return;
                        }
                        _editProfile(context, ref, profile);
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionHeading(
                      title: 'About me',
                      trailing: IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () {
                          if (isDemoMode) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile editing is unavailable in demo preview.',
                                ),
                              ),
                            );
                            return;
                          }
                          _editProfile(context, ref, profile);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          profile?.bio.trim().isNotEmpty == true
                              ? profile!.bio
                              : 'Add a short bio about yourself.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: profile?.bio.trim().isNotEmpty == true
                                    ? null
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading(title: 'Posts and contributions'),
                    _ActivityCard(
                      reportCount: reportCount,
                      resourceCount: resourceCount,
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading(title: 'Student information'),
                    Card(
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.school_outlined,
                            title: 'Department',
                            value: profile?.departmentId.toUpperCase() ?? 'DIU',
                          ),
                          const Divider(height: 1, indent: 64),
                          _InfoTile(
                            icon: Icons.badge_outlined,
                            title: 'Student ID',
                            value: profile?.studentId ?? 'Not specified',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading(title: 'Settings'),
                    Card(
                      child: Column(
                        children: [
                          _DarkModeSetting(
                            themeMode: ref.watch(themeModeProvider),
                            onChanged: (enabled) {
                              ref.read(themeModeProvider.notifier).state =
                                  enabled ? ThemeMode.dark : ThemeMode.light;
                            },
                          ),
                          const Divider(height: 1, indent: 64),
                          ListTile(
                            leading: const Icon(Icons.lock_reset_outlined),
                            title: const Text('Change password'),
                            subtitle:
                                const Text('We will email you a reset link'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/forgot-password'),
                          ),
                          const Divider(height: 1, indent: 64),
                          ListTile(
                            leading: Icon(
                              Icons.logout,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Sign out',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => _signOut(context, ref),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'DIU Report Box  •  v1.0.0',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your profile: $error'),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? profile;
  final String name;
  final String email;
  final bool isAdmin;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.profile,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile?.photoUrl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_profileBlue, _profileTeal],
        ),
        boxShadow: [
          BoxShadow(
            color: _profileBlue.withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: Colors.white,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _AvatarInitial(name: name),
                    ),
                  )
                : _AvatarInitial(name: name),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text(
                isAdmin ? 'Administrator' : 'DIU Student',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String name;

  const _AvatarInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'S',
      style: const TextStyle(
        color: _profileBlue,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final AsyncValue<int> reportCount;
  final AsyncValue<int> resourceCount;

  const _ActivityCard({
    required this.reportCount,
    required this.resourceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _ActivityStat(
                title: 'Reports submitted',
                icon: Icons.assignment_outlined,
                count: reportCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActivityStat(
                title: 'Resources shared',
                icon: Icons.menu_book_outlined,
                count: resourceCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<int> count;

  const _ActivityStat({
    required this.title,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _profileBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _profileBlue, size: 24),
          const SizedBox(height: 14),
          count.when(
            data: (value) => Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _profileBlue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            loading: () => const SizedBox(
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, _) => Tooltip(
              message: 'Could not load $title: $error',
              child: Text(
                'Unavailable',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeading({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _profileBlue),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}

class _DarkModeSetting extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onChanged;

  const _DarkModeSetting({
    required this.themeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: const Icon(Icons.dark_mode_outlined, color: _profileBlue),
      title: const Text('Dark mode'),
      subtitle: const Text('Use a darker appearance throughout the app'),
      value: themeMode == ThemeMode.dark,
      activeTrackColor: _profileBlue,
      onChanged: onChanged,
    );
  }
}

Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  UserModel? profile,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: profile?.name ?? '');
  final bioController = TextEditingController(text: profile?.bio ?? '');

  try {
    final updates = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bioController,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell your campus community about yourself',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop({
                  'name': nameController.text.trim(),
                  'bio': bioController.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updates == null || !context.mounted) return;

    await ref.read(authRepositoryProvider).updateProfile(
          name: updates['name']!,
          bio: updates['bio']!,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
    }
  } finally {
    nameController.dispose();
    bioController.dispose();
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'Are you sure you want to log out of DIU Report Box?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await ref.read(authControllerProvider.notifier).signOut();
  if (context.mounted) context.go('/login');
}
