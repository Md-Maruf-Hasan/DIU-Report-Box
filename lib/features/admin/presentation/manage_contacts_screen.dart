import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../reports/presentation/report_providers.dart';
import 'admin_providers.dart';

class ManageContactsScreen extends ConsumerStatefulWidget {
  const ManageContactsScreen({super.key});

  @override
  ConsumerState<ManageContactsScreen> createState() => _ManageContactsScreenState();
}

class _ManageContactsScreenState extends ConsumerState<ManageContactsScreen> {
  String _selectedDeptId = 'swe';

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final contactsAsync = ref.watch(departmentContactsProvider(_selectedDeptId));

    return Column(
      children: [
        // Department Picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Text('Department: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              departmentsAsync.when(
                data: (depts) {
                  return DropdownButton<String>(
                    value: _selectedDeptId,
                    items: depts.map((d) {
                      return DropdownMenuItem(value: d.id, child: Text('${d.code} - ${d.name}'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDeptId = val);
                    },
                  );
                },
                loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Text('Error: $e'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddContactDialog(context, _selectedDeptId),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Staff'),
              ),
            ],
          ),
        ),

        // Contacts List
        Expanded(
          child: contactsAsync.when(
            data: (contacts) {
              if (contacts.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.phone_disabled_outlined,
                  title: 'No maintenance contacts configured',
                  subtitle: 'Add staff phone numbers to receive automated SMS alerts for this department.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: contacts.length,
                itemBuilder: (context, idx) {
                  final c = contacts[idx];
                  final name = c['name'] as String? ?? 'Staff';
                  final phone = c['phone'] as String? ?? '';
                  final active = c['active'] as bool? ?? true;
                  final categories = List<String>.from(c['categories'] as List? ?? []);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade200,
                        child: Icon(
                          Icons.phone,
                          color: active ? Colors.green.shade800 : Colors.grey,
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(phone),
                          if (categories.isNotEmpty)
                            Text(
                              'Categories: ${categories.join(', ')}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            )
                          else
                            Text('All categories', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      trailing: Switch(
                        value: active,
                        onChanged: (newActive) {
                          ref.read(adminRepositoryProvider).saveMaintenanceContact(
                                departmentId: _selectedDeptId,
                                contactId: c['id'],
                                name: name,
                                phone: phone,
                                active: newActive,
                                categories: categories,
                              );
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _showAddContactDialog(BuildContext context, String deptId) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Maintenance Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Staff Name / Designation',
                hintText: 'Md. Rafiqul Islam (Lab Maintenance)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Bangladesh format)',
                hintText: '8801712345678',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty && phoneController.text.trim().isNotEmpty) {
                await ref.read(adminRepositoryProvider).saveMaintenanceContact(
                      departmentId: deptId,
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      active: true,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }
}
