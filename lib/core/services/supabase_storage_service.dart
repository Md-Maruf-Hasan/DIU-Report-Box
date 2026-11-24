import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../app/constants.dart';

class SupabaseStorageService {
  SupabaseStorageService();

  Future<String> uploadFile({
    required File file,
    required String folder,
    required String contentType,
  }) async {
    if (AppConstants.supabaseUrl.isEmpty ||
        AppConstants.supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    final originalName = file.path.split(Platform.pathSeparator).last;
    final extension = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final fileName = '${const Uuid().v4()}$extension';
    final objectPath = '$folder/$fileName';
    final bytes = await file.readAsBytes();

    await Supabase.instance.client.storage
        .from(
          AppConstants.supabaseStorageBucket,
        )
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return Supabase.instance.client.storage
        .from(AppConstants.supabaseStorageBucket)
        .getPublicUrl(objectPath);
  }
}
