import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/lost_found_model.dart';
import '../data/lost_found_repository.dart';

final lostFoundRepositoryProvider = Provider<LostFoundRepository>((ref) {
  return LostFoundRepository();
});

class LostFoundFilterState {
  final String typeFilter; // 'all' | 'lost' | 'found' | 'resolved'
  final String categoryFilter; // 'all' or category
  final String searchQuery;

  const LostFoundFilterState({
    this.typeFilter = 'all',
    this.categoryFilter = 'all',
    this.searchQuery = '',
  });

  LostFoundFilterState copyWith({
    String? typeFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return LostFoundFilterState(
      typeFilter: typeFilter ?? this.typeFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final lostFoundFilterProvider =
    StateProvider<LostFoundFilterState>((ref) => const LostFoundFilterState());

final lostFoundFeedProvider = StreamProvider<List<LostFoundModel>>((ref) {
  final filters = ref.watch(lostFoundFilterProvider);
  return ref.watch(lostFoundRepositoryProvider).watchFeed(
        typeFilter: filters.typeFilter,
        categoryFilter: filters.categoryFilter,
        searchQuery: filters.searchQuery,
      );
});

class LostFoundController extends StateNotifier<AsyncValue<void>> {
  final LostFoundRepository _repo;

  LostFoundController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> createPost({
    required String type,
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime date,
    required List<File> imageFiles,
    String? contact,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createPost(
        type: type,
        title: title,
        description: description,
        category: category,
        location: location,
        date: date,
        imageFiles: imageFiles,
        contact: contact,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> markResolved(String postId) async {
    await _repo.markResolved(postId);
  }

  Future<void> deletePost(String postId) async {
    await _repo.deletePost(postId);
  }

  Future<void> reportContent(String postId, String reason) async {
    await _repo.reportContent(targetId: postId, reason: reason);
  }
}

final lostFoundControllerProvider =
    StateNotifierProvider<LostFoundController, AsyncValue<void>>((ref) {
  return LostFoundController(ref.watch(lostFoundRepositoryProvider));
});
