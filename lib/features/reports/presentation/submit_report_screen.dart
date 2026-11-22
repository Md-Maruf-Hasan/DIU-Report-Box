import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/constants.dart';
import '../../../core/validators.dart';
import 'my_reports_screen.dart';
import 'report_providers.dart';

class SpecificReportMainScreen extends StatefulWidget {
  const SpecificReportMainScreen({super.key});

  @override
  State<SpecificReportMainScreen> createState() => _SpecificReportMainScreenState();
}

class _SpecificReportMainScreenState extends State<SpecificReportMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.add_task), text: 'Submit Report'),
              Tab(icon: Icon(Icons.history), text: 'My Reports'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SubmitReportForm(
            onSuccess: () => _tabController.animateTo(1),
          ),
          const MyReportsScreen(),
        ],
      ),
    );
  }
}

class SubmitReportForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const SubmitReportForm({super.key, required this.onSuccess});

  @override
  ConsumerState<SubmitReportForm> createState() => _SubmitReportFormState();
}

class _SubmitReportFormState extends ConsumerState<SubmitReportForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDeptId;
  String? _selectedRoomId;
  String? _selectedRoomNo;
  String _selectedCategory = AppConstants.reportCategories.first;
  final _descController = TextEditingController();
  final List<File> _attachedImages = [];
  bool _duplicateWarning = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicate() async {
    if (_selectedDeptId != null && _selectedRoomNo != null) {
      if (AppConstants.demoPreview) return;
      final isDup = await ref.read(reportControllerProvider.notifier).checkSimilar(
            _selectedDeptId!,
            _selectedRoomNo!,
            _selectedCategory,
          );
      if (mounted) {
        setState(() => _duplicateWarning = isDup);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_attachedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed.')),
      );
      return;
    }

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final file = File(picked.path);
      final size = await file.length();
      if (size > AppConstants.maxImageSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be under 5MB.')),
        );
        return;
      }
      setState(() => _attachedImages.add(file));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null || _selectedRoomId == null || _selectedRoomNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Department and Room.')),
      );
      return;
    }

    final refNo = await ref.read(reportControllerProvider.notifier).submitReport(
          departmentId: _selectedDeptId!,
          roomId: _selectedRoomId!,
          roomNo: _selectedRoomNo!,
          category: _selectedCategory,
          description: _descController.text.trim(),
          imageFiles: _attachedImages,
        );

    if (refNo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted successfully! Ref: $refNo'),
          backgroundColor: Colors.green.shade800,
        ),
      );
      _descController.clear();
      setState(() {
        _attachedImages.clear();
        _duplicateWarning = false;
      });
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppConstants.demoPreview
        ? const AsyncValue<void>.data(null)
        : ref.watch(reportControllerProvider);
    final isLoading = state.isLoading;
    final departmentsAsync = ref.watch(departmentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Header Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF006A4E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your report will automatically dispatch an SMS alert directly to the department maintenance staff.',
                      style: TextStyle(color: Colors.green.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (state.hasError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  state.error.toString().replaceAll('Exception: ', ''),
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Department Dropdown
            departmentsAsync.when(
              data: (departments) {
                return DropdownButtonFormField<String>(
                  value: _selectedDeptId,
                  decoration: const InputDecoration(
                    labelText: 'Select Department',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  items: departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept.id,
                      child: Text('${dept.code} - ${dept.name}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDeptId = val;
                      _selectedRoomId = null;
                      _selectedRoomNo = null;
                    });
                    _checkDuplicate();
                  },
                  validator: (val) => val == null ? 'Please select a department' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading departments: $e'),
            ),
            const SizedBox(height: 16),

            // Room Dropdown (filtered by department)
            if (_selectedDeptId != null) ...[
              Consumer(
                builder: (context, ref, child) {
                  final roomsAsync = ref.watch(roomsForDepartmentProvider(_selectedDeptId!));
                  return roomsAsync.when(
                    data: (rooms) {
                      if (rooms.isEmpty) {
                        return const Text('No rooms registered for this department.');
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedRoomId,
                        decoration: const InputDecoration(
                          labelText: 'Select Room / Lab',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                        items: rooms.map((room) {
                          return DropdownMenuItem(
                            value: room.id,
                            child: Text('Room ${room.roomNo} (${room.floor ?? "Academic"})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final selected = rooms.firstWhere((r) => r.id == val);
                          setState(() {
                            _selectedRoomId = val;
                            _selectedRoomNo = selected.roomNo;
                          });
                          _checkDuplicate();
                        },
                        validator: (val) => val == null ? 'Please select a room' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading rooms: $e'),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Issue Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.reportCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                  _checkDuplicate();
                }
              },
            ),
            const SizedBox(height: 16),

            // Duplicate Report Warning Hint
            if (_duplicateWarning) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A similar report is already active for this room & category. Our team is already looking into it.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Issue Description (min 15 characters)',
                hintText: 'e.g. PC #4 is not turning on. Monitor power LED is blinking orange.',
              ),
              validator: Validators.validateReportDescription,
            ),
            const SizedBox(height: 16),

            // Photos Section (up to 3)
            Text('Attach Evidence Photos (up to 3)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                ..._attachedImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(entry.value),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _attachedImages.removeAt(entry.key)),
                          child: Container(
                            color: Colors.black54,
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_attachedImages.length < 3)
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading || AppConstants.demoPreview ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report to Maintenance', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
