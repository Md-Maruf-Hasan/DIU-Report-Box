import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants.dart';
import '../../../core/models/resource_model.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'resource_providers.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _subsections = [
    'previous_questions',
    'notes',
    'others',
  ];

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
    final filters = ref.watch(resourceFilterProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(104),
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by course code or title...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  ref.read(resourceFilterProvider.notifier).state =
                      filters.copyWith(searchQuery: val);
                },
              ),
            ),

            // Tab bar for 3 subsections
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Questions'),
                Tab(text: 'Notes'),
                Tab(text: 'Others'),
              ],
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _subsections
            .map((sub) => _ResourceListView(subsection: sub))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'resources-upload',
        onPressed: AppConstants.demoPreview
            ? null
            : () {
                final activeSub = _subsections[_tabController.index];
                context.push('/resources/upload', extra: activeSub);
              },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }
}

class _ResourceListView extends ConsumerWidget {
  final String subsection;

  const _ResourceListView({required this.subsection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesBySubsectionProvider(subsection));

    return resourcesAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateView(
            icon: Icons.folder_open_outlined,
            title: 'No materials uploaded yet',
            subtitle:
                'Upload past exam papers, lecture notes, or study materials to help your fellow students.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(resourcesBySubsectionProvider(subsection)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final item = items[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      _getIcon(item),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.courseCode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.term,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.courseTitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: AppConstants.demoPreview
                      ? null
                      : () =>
                          context.push('/resources/${item.id}', extra: item),
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingSkeletonList(itemCount: 4),
      error: (e, _) => ErrorRetryView(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(resourcesBySubsectionProvider(subsection)),
      ),
    );
  }

  IconData _getIcon(ResourceModel item) {
    if (item.attachments.any((a) => a.kind == 'pdf'))
      return Icons.picture_as_pdf;
    if (item.attachments.any((a) => a.kind == 'image')) return Icons.image;
    return Icons.link;
  }
}
