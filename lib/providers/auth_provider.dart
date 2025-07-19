import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  app_user.User? _userData;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get firebaseUser => _firebaseUser;
  app_user.User? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAdmin => _userData?.isAdmin ?? false;
  bool get isModerator => _userData?.isModerator ?? false;
  bool get canAccessAdminPanel => _userData?.canAccessAdminPanel ?? false;

  // Initialize auth provider
  void initialize() {
    _firebaseUser = _authService.currentUser;
    if (_firebaseUser != null) {
      _loadUserData();
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;

    try {
      _setLoading(true);
      _userData = await _authService.getUserData(_firebaseUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError('فشل في تحميل بيانات المستخدم: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      _firebaseUser = credential.user;

      if (_firebaseUser != null) {
        await _loadUserData();

        // Check if user can access admin panel
        // Geçici olarak devre dışı bırakıldı
        // if (!canAccessAdminPanel) {
        //   await signOut();
        //   _setError('ليس لديك صلاحية للوصول إلى لوحة الإدارة');
        //   return false;
        // }

        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up
  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
        displayName,
      );

      _firebaseUser = credential.user;

      if (_firebaseUser != null) {
        await _loadUserData();
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _firebaseUser = null;
      _userData = null;
      notifyListeners();
    } catch (e) {
      _setError('فشل في تسجيل الخروج: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updatePassword(newPassword);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    if (_firebaseUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserData(_firebaseUser!.uid, data);
      await _loadUserData(); // Reload user data
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      await _loadUserData();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
