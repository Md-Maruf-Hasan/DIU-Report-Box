import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCM] Push notifications authorized.');
        final token = await _messaging.getToken();
        if (token != null) {
          await saveTokenToUser(token);
        }

        _messaging.onTokenRefresh.listen((newToken) async {
          await saveTokenToUser(newToken);
        });
      }
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  static Future<void> saveTokenToUser(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      debugPrint('[FCM] Token synced for user ${user.uid}');
    } catch (e) {
      debugPrint('[FCM] Failed to update user token: $e');
    }
  }
}
