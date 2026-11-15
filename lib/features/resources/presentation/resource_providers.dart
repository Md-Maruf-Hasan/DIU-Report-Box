import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/resource_model.dart';
import '../data/resource_repository.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository();
});

class ResourceFilterState {
  final String departmentId; // 'all' or dept id
  final String courseCode;
  final String searchQuery;

  const ResourceFilterState({
    this.departmentId = 'all',
    this.courseCode = '',
    this.searchQuery = '',
  });

  ResourceFilterState copyWith({
    String? departmentId,
    String? courseCode,
    String? searchQuery,
  }) {
    return ResourceFilterState(
      departmentId: departmentId ?? this.departmentId,
      courseCode: courseCode ?? this.courseCode,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final resourceFilterProvider =
    StateProvider<ResourceFilterState>((ref) => const ResourceFilterState());

final resourcesBySubsectionProvider =
    StreamProvider.family<List<ResourceModel>, String>((ref, subsection) {
  final filters = ref.watch(resourceFilterProvider);
  return ref.watch(resourceRepositoryProvider).watchResources(
        subsection: subsection,
        departmentId: filters.departmentId,
        courseCode: filters.courseCode,
        searchQuery: filters.searchQuery,
      );
});

class ResourceController extends StateNotifier<AsyncValue<void>> {
  final ResourceRepository _repo;

  ResourceController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> uploadResource({
    required String subsection,
    required String title,
    required String departmentId,
    required String courseCode,
    required String courseTitle,
    required String term,
    String? description,
    required List<File> files,
    required List<String> fileKinds,
    String? externalLink,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.uploadResource(
        subsection: subsection,
        title: title,
        departmentId: departmentId,
        courseCode: courseCode,
        courseTitle: courseTitle,
        term: term,
        description: description,
        files: files,
        fileKinds: fileKinds,
        externalLink: externalLink,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteResource(String id) async {
    await _repo.deleteResource(id);
  }

  Future<void> reportResource(String id, String reason) async {
    await _repo.reportResource(id, reason);
  }
}

final resourceControllerProvider =
    StateNotifierProvider<ResourceController, AsyncValue<void>>((ref) {
  return ResourceController(ref.watch(resourceRepositoryProvider));
});
