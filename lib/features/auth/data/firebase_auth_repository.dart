import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_role.dart';

/// Firebase Auth handles passwords and sessions. Each user's name and ROLE
/// live in Firestore at `users/{uid}`. Self-registration can only ever create
/// an `aspirant`; the security rules (firestore.rules) stop anyone from
/// giving themselves a higher role. Only an admin can change roles.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Future<AppUser?> restoreSession() async {
    // The first event carries the saved session (or null) once Firebase is ready.
    final firebaseUser = await _auth.authStateChanges().first;
    if (firebaseUser == null) return null;
    try {
      return await _loadProfile(firebaseUser);
    } catch (_) {
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _loadProfile(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    } on FirebaseException catch (e) {
      await _auth.signOut();
      throw AuthException('Could not load your profile (${e.code}).');
    }
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await _createAspirantProfile(
        user.uid,
        name.trim(),
        user.email ?? email.trim(),
      );
      return AppUser(
        id: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
        role: UserRole.aspirant,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    } on FirebaseException catch (e) {
      throw AuthException('Could not save your profile (${e.code}).');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _createAspirantProfile(String uid, String name, String email) {
    return _users.doc(uid).set({
      'name': name,
      'email': email,
      'role': UserRole.aspirant.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser> _loadProfile(User firebaseUser) async {
    final ref = _users.doc(firebaseUser.uid);
    var snapshot = await ref.get();

    // An account without a profile (e.g. created in the Firebase console)
    // becomes an aspirant. The rules only allow the aspirant role here.
    if (!snapshot.exists) {
      await _createAspirantProfile(
        firebaseUser.uid,
        firebaseUser.displayName ?? firebaseUser.email ?? 'New user',
        firebaseUser.email ?? '',
      );
      snapshot = await ref.get();
    }

    final data = snapshot.data()!;
    return AppUser(
      id: firebaseUser.uid,
      name:
          (data['name'] as String?) ??
          firebaseUser.displayName ??
          firebaseUser.email ??
          'User',
      email: firebaseUser.email ?? '',
      role: UserRole.parse(data['role'] as String?),
      department: data['department'] as String?,
      level: (data['level'] as num?)?.toInt(),
    );
  }

  String _authMessage(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'invalid-email' => 'Enter a valid email address.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Password is too weak. Use at least 6 characters.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'No internet connection. Check your network.',
    _ => 'Authentication failed (${e.code}).',
  };
}
