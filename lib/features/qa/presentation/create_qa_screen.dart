import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/validators.dart';
import 'qa_providers.dart';

class CreateQaScreen extends ConsumerStatefulWidget {
  const CreateQaScreen({super.key});

  @override
  ConsumerState<CreateQaScreen> createState() => _CreateQaScreenState();
}

class _CreateQaScreenState extends ConsumerState<CreateQaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isAnonymous = false;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(qaControllerProvider.notifier).createPost(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          isAnonymous: _isAnonymous,
          imageFile: _selectedImage,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAnonymous
              ? 'Anonymous question posted.'
              : 'Question posted successfully!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qaControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question / Discuss'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Anonymous Toggle Switch Card
                Card(
                  color: _isAnonymous ? Colors.blueGrey.shade50 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: _isAnonymous ? Colors.blueGrey : Colors.grey.shade300,
                    ),
                  ),
                  child: SwitchListTile(
                    value: _isAnonymous,
                    title: const Text(
                      'Post Anonymously',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Your name and profile will be hidden from other students.',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      Icons.masks_outlined,
                      color: _isAnonymous ? Colors.blueGrey : Colors.grey,
                    ),
                    onChanged: (val) => setState(() => _isAnonymous = val),
                  ),
                ),
                const SizedBox(height: 16),

                // Question Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Question / Topic Title',
                    hintText: 'e.g. Tips for Software Testing final exam?',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Title'),
                ),
                const SizedBox(height: 16),

                // Question Body
                TextFormField(
                  controller: _bodyController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Description / Question Details',
                    hintText: 'Elaborate your question, provide context or code snippets...',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Description'),
                ),
                const SizedBox(height: 16),

                // Attached Image preview
                if (_selectedImage != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onPressed: () => setState(() => _selectedImage = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_selectedImage == null ? 'Attach Image (Optional)' : 'Change Image'),
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
                      : const Text('Post Question', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
