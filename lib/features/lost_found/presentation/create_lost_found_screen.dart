import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../app/constants.dart';
import '../../../core/validators.dart';
import 'lost_found_providers.dart';

class CreateLostFoundScreen extends ConsumerStatefulWidget {
  const CreateLostFoundScreen({super.key});

  @override
  ConsumerState<CreateLostFoundScreen> createState() => _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState extends ConsumerState<CreateLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'lost';
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = AppConstants.lostFoundCategories.first;
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<File> _selectedImages = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to 3 images.')),
      );
      return;
    }

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final file = File(picked.path);
      final size = await file.length();
      if (size > AppConstants.maxImageSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be 5MB or less.')),
        );
        return;
      }
      setState(() {
        _selectedImages.add(file);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(lostFoundControllerProvider.notifier).createPost(
          type: _type,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          location: _locationController.text.trim(),
          date: _selectedDate,
          imageFiles: _selectedImages,
          contact: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lostFoundControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Lost / Found Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector SegmentedButton
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'lost',
                      label: Text('I Lost Something'),
                      icon: Icon(Icons.search),
                    ),
                    ButtonSegment(
                      value: 'found',
                      label: Text('I Found Something'),
                      icon: Icon(Icons.pan_tool_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _type = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Item Title',
                    hintText: 'e.g. Black Dell Laptop Bag / Student ID Card',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Title'),
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: AppConstants.lostFoundCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / Spot',
                    hintText: 'e.g. SWE Lab 703, Library 2nd floor, Canteen',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Location'),
                ),
                const SizedBox(height: 16),

                // Date Picker Tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Incident Date'),
                  subtitle: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Description',
                    hintText: 'Describe color, unique stickers, keychains, markings...',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Description'),
                ),
                const SizedBox(height: 16),

                // Contact info
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Information (Optional)',
                    hintText: 'Phone number or how finder/owner can reach you',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Image Picker (up to 3)
                Text(
                  'Attach Photos (up to 3)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ..._selectedImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(idx)),
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_selectedImages.length < 3)
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
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Publish Post', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
