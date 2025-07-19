import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(credential.user!, displayName);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('فشل في تسجيل الخروج: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<app_user.User?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return app_user.User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب بيانات المستخدم: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      throw Exception('فشل في تحديث بيانات المستخدم: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      final userData = app_user.User(
        id: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        role: app_user.UserRole.admin, // Yeni kullanıcıları admin yap
        status: app_user.UserStatus.active,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userData.toFirestore());
    } catch (e) {
      throw Exception('فشل في إنشاء وثيقة المستخدم: $e');
    }
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'lastLoginAt': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      // Log error but don't throw exception
      print('Failed to update last login: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لم يتم العثور على المستخدم';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز الحد الأقصى للمحاولات، يرجى المحاولة لاحقاً';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'network-request-failed':
        return 'فشل في الاتصال بالشبكة';
      default:
        return 'حدث خطأ غير متوقع: ${e.message}';
    }
  }

  // Check if user has admin privileges
  Future<bool> isAdmin(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if user has moderator privileges
  Future<bool> isModerator(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?.isModerator ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if user can access admin panel
  Future<bool> canAccessAdminPanel(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?.canAccessAdminPanel ?? false;
    } catch (e) {
      return false;
    }
  }
}
