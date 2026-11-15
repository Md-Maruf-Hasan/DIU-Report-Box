import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/constants.dart';
import '../../../core/validators.dart';
import 'resource_providers.dart';

class UploadResourceScreen extends ConsumerStatefulWidget {
  final String initialSubsection;

  const UploadResourceScreen({
    super.key,
    this.initialSubsection = 'previous_questions',
  });

  @override
  ConsumerState<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends ConsumerState<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _subsection;
  final _titleController = TextEditingController();
  String _departmentId = 'swe';
  final _courseCodeController = TextEditingController();
  final _courseTitleController = TextEditingController();
  final _termController = TextEditingController(text: 'Fall 2026');
  final _descController = TextEditingController();
  final _linkController = TextEditingController();

  final List<File> _attachedFiles = [];
  final List<String> _attachedFileKinds = []; // 'image' | 'pdf'

  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, String>> _departments = [
    {'code': 'SWE', 'name': 'Software Engineering'},
    {'code': 'CSE', 'name': 'Computer Science & Engineering'},
    {'code': 'EEE', 'name': 'Electrical & Electronic Engineering'},
    {'code': 'BBA', 'name': 'Business Administration'},
    {'code': 'CE', 'name': 'Civil Engineering'},
    {'code': 'ENG', 'name': 'English'},
    {'code': 'PHARM', 'name': 'Pharmacy'},
  ];

  @override
  void initState() {
    super.initState();
    _subsection = widget.initialSubsection;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _termController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
      setState(() {
        _attachedFiles.add(file);
        _attachedFileKinds.add('image');
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();
      if (size > AppConstants.maxPdfSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF must be under 10MB.')),
        );
        return;
      }
      setState(() {
        _attachedFiles.add(file);
        _attachedFileKinds.add('pdf');
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasLink = _linkController.text.trim().isNotEmpty;
    if (_attachedFiles.isEmpty && !hasLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a file (PDF/Image) or provide an external link.')),
      );
      return;
    }

    if (_subsection == 'previous_questions' && hasLink && _attachedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Previous Questions only accept direct PDF or Image files.')),
      );
      return;
    }

    final success = await ref.read(resourceControllerProvider.notifier).uploadResource(
          subsection: _subsection,
          title: _titleController.text.trim(),
          departmentId: _departmentId,
          courseCode: _courseCodeController.text.trim().toUpperCase(),
          courseTitle: _courseTitleController.text.trim(),
          term: _termController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          files: _attachedFiles,
          fileKinds: _attachedFileKinds,
          externalLink: hasLink ? _linkController.text.trim() : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource uploaded successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resourceControllerProvider);
    final isLoading = state.isLoading;
    final allowsLink = _subsection != 'previous_questions';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resource'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subsection selector
                DropdownButtonFormField<String>(
                  value: _subsection,
                  decoration: const InputDecoration(labelText: 'Resource Category'),
                  items: const [
                    DropdownMenuItem(value: 'previous_questions', child: Text('Previous Questions (PDF/Image)')),
                    DropdownMenuItem(value: 'notes', child: Text('Lecture Notes (PDF/Image/Link)')),
                    DropdownMenuItem(value: 'others', child: Text('Other Materials (PDF/Image/Link)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _subsection = val);
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Title',
                    hintText: 'e.g. Midterm Question Summer 2026 / Chapter 4 Notes',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Title'),
                ),
                const SizedBox(height: 16),

                // Department
                DropdownButtonFormField<String>(
                  value: _departmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _departments.map((d) {
                    return DropdownMenuItem(
                      value: d['code']!.toLowerCase(),
                      child: Text('${d['code']} - ${d['name']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _departmentId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Course Code and Title
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _courseCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Course Code',
                          hintText: 'SWE 312',
                        ),
                        validator: (val) => Validators.validateRequired(val, 'Course code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _termController,
                        decoration: const InputDecoration(
                          labelText: 'Semester / Term',
                          hintText: 'Fall 2026',
                        ),
                        validator: (val) => Validators.validateRequired(val, 'Term'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _courseTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
                    hintText: 'e.g. Software Testing & Quality Assurance',
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Course title'),
                ),
                const SizedBox(height: 16),

                // Description (optional)
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Description (Optional)',
                  ),
                ),
                const SizedBox(height: 20),

                // Attachments List
                Text('Attached Files', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),

                if (_attachedFiles.isEmpty)
                  Text('No files attached yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),

                ..._attachedFiles.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final file = entry.value;
                  final kind = _attachedFileKinds[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: Icon(kind == 'pdf' ? Icons.picture_as_pdf : Icons.image),
                      title: Text(file.path.split(Platform.pathSeparator).last),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _attachedFiles.removeAt(idx);
                            _attachedFileKinds.removeAt(idx);
                          });
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Action buttons to pick PDF or Image
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Add PDF (<=10MB)'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Add Image (<=5MB)'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // External Link (if allowed)
                if (allowsLink) ...[
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'Google Drive / External Resource Link (Optional)',
                      hintText: 'https://drive.google.com/...',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        return Validators.validateHttpsUrl(val);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Publish Resource Material', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
