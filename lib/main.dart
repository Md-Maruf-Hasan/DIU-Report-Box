import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/constants.dart';
import 'app/demo_preview.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/fcm_service.dart';

bool _firebaseInitFailed = false;

bool get useDemoMode => AppConstants.demoPreview || _firebaseInitFailed;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConstants.demoPreview) {
    try {
      await Firebase.initializeApp();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await FcmService.initialize();
    } catch (e) {
      debugPrint('[Firebase] Initialization failed: $e');
      debugPrint('[Firebase] Falling back to demo preview mode.');
      _firebaseInitFailed = true;
    }

    if (!_firebaseInitFailed &&
        AppConstants.supabaseUrl.isNotEmpty &&
        AppConstants.supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          publishableKey: AppConstants.supabaseAnonKey,
          accessToken: () async {
            final user = FirebaseAuth.instance.currentUser;
            return await user?.getIdToken();
          },
        );
      } catch (e) {
        debugPrint('[Supabase] Initialization failed; uploads are unavailable: $e');
      }
    } else if (!_firebaseInitFailed) {
      debugPrint(
        '[Supabase] URL or publishable key is missing; file uploads will be unavailable.',
      );
    }
  }

  runApp(
    ProviderScope(
      overrides: useDemoMode ? demoPreviewOverrides : const [],
      child: const DiuReportBoxApp(),
    ),
  );
}

class DiuReportBoxApp extends ConsumerWidget {
  const DiuReportBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
