import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/constants.dart';
import '../../../core/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String departmentId,
    String? studentId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.endsWith('@${AppConstants.allowedEmailDomain}')) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Only @${AppConstants.allowedEmailDomain} emails are allowed.',
      );
    }

    // 1. Create Firebase Auth user
    final cred = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = cred.user!;

    // 2. Send verification email
    await user.sendEmailVerification();

    // 3. Create Firestore user document
    final userModel = UserModel(
      uid: user.uid,
      name: name.trim(),
      email: cleanEmail,
      departmentId: departmentId,
      studentId: studentId?.trim(),
      role: 'student',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

    return userModel;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    await credential.user?.getIdToken(true);
    return credential;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final reloadedUser = _auth.currentUser;
    final isVerified = reloadedUser?.emailVerified ?? false;
    if (isVerified) await reloadedUser?.getIdToken(true);
    return isVerified;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to update your profile.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'name': name.trim(),
      'bio': bio.trim(),
    });
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
