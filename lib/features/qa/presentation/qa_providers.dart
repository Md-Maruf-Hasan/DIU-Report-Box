import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/qa_post_model.dart';
import '../data/qa_repository.dart';

final qaRepositoryProvider = Provider<QaRepository>((ref) {
  return QaRepository();
});

class QaFilterState {
  final String sortBy; // 'newest' | 'active'
  final String searchQuery;

  const QaFilterState({
    this.sortBy = 'newest',
    this.searchQuery = '',
  });

  QaFilterState copyWith({
    String? sortBy,
    String? searchQuery,
  }) {
    return QaFilterState(
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final qaFilterProvider = StateProvider<QaFilterState>((ref) => const QaFilterState());

final qaFeedProvider = StreamProvider<List<QaPostModel>>((ref) {
  final filters = ref.watch(qaFilterProvider);
  return ref.watch(qaRepositoryProvider).watchFeed(
        sortBy: filters.sortBy,
        searchQuery: filters.searchQuery,
      );
});

final qaCommentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(qaRepositoryProvider).watchComments(postId);
});

final isLikedProvider = StreamProvider.family<bool, String>((ref, postId) {
  return ref.watch(qaRepositoryProvider).isLiked(postId);
});

class QaController extends StateNotifier<AsyncValue<void>> {
  final QaRepository _repo;

  QaController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> createPost({
    required String title,
    required String body,
    required bool isAnonymous,
    File? imageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createPost(
        title: title,
        body: body,
        isAnonymous: isAnonymous,
        imageFile: imageFile,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addComment({
    required String postId,
    required String text,
    required bool isAnonymous,
  }) async {
    try {
      await _repo.addComment(
        postId: postId,
        text: text,
        isAnonymous: isAnonymous,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    await _repo.toggleLike(postId);
  }

  Future<void> deletePost(QaPostModel post) async {
    await _repo.deletePost(post);
  }

  Future<void> deleteComment(String postId, CommentModel comment) async {
    await _repo.deleteComment(postId, comment);
  }

  Future<void> reportContent(String type, String targetId, String reason) async {
    await _repo.reportQaContent(targetType: type, targetId: targetId, reason: reason);
  }
}

final qaControllerProvider =
    StateNotifierProvider<QaController, AsyncValue<void>>((ref) {
  return QaController(ref.watch(qaRepositoryProvider));
});
