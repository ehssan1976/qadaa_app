import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  static const String _firebaseApiKey = 'AIzaSyDfyw_LdBBhImg2cqa1qHr4qaRopqcBzxY';
  static const String _identityToolkitBase = 'https://identitytoolkit.googleapis.com/v1/accounts';

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth instance unavailable: $e');
      return null;
    }
  }

  // Session state cache for REST fallback across all platforms
  String? _idToken;
  String? _currentEmail;
  String? _localId;
  bool _isRestVerified = false;

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      final a = _auth;
      if (a != null) return a.authStateChanges();
    } catch (_) {}
    return const Stream.empty();
  }

  String? get userEmail => currentUser?.email ?? _currentEmail;

  /// Fast synchronous check of verification
  bool get isEmailVerified => (currentUser?.emailVerified ?? false) || _isRestVerified;

  /// Thorough asynchronous verification check from server
  Future<bool> checkIsEmailVerified() async {
    // 1. Try Firebase Auth SDK reload if available
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await user.reload();
        final refreshed = _auth?.currentUser;
        if (refreshed != null && refreshed.emailVerified) {
          _isRestVerified = true;
          return true;
        }
      }
    } catch (e) {
      debugPrint('SDK reload check error: $e');
    }

    // 2. Try REST API lookup with cached token or stored token
    final token = await _getIdToken();
    if (token != null && token.isNotEmpty) {
      try {
        final verified = await _lookupEmailVerifiedFromRest(token);
        if (verified) {
          _isRestVerified = true;
          return true;
        }
      } catch (e) {
        debugPrint('REST email verification lookup error: $e');
      }
    }

    return false;
  }

  /// Reload current user profile from Firebase to fetch updated verification status
  Future<User?> reloadUser() async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await user.reload();
        return _auth?.currentUser;
      }
    } catch (_) {}
    return null;
  }

  /// Register a new account with Email and Password
  /// and automatically send a real email verification message to their official email.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    String? tokenForVerification;

    // 1. Try Firebase Auth SDK first
    bool sdkSuccess = false;
    try {
      final a = _auth;
      if (a != null) {
        final credential = await a.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        sdkSuccess = true;
        tokenForVerification = await credential.user?.getIdToken();
        _currentEmail = cleanEmail;
        _localId = credential.user?.uid;
        _isRestVerified = false;

        // Send verification email via SDK
        try {
          await credential.user?.sendEmailVerification();
          debugPrint('✅ Firebase SDK sendEmailVerification success for $cleanEmail');
        } catch (e) {
          debugPrint('⚠️ SDK sendEmailVerification failed, falling back to REST: $e');
          if (tokenForVerification != null) {
            await _sendEmailVerificationRest(tokenForVerification);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      debugPrint('SDK signup exception (will fallback to REST): $e');
    }

    // 2. Fallback to Firebase REST API if SDK was not used or failed due to platform
    if (!sdkSuccess) {
      try {
        final res = await http.post(
          Uri.parse('$_identityToolkitBase:signUp?key=$_firebaseApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            'password': password,
            'returnSecureToken': true,
          }),
        );

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 200) {
          throw _parseRestError(data);
        }

        _idToken = data['idToken'] as String?;
        _currentEmail = cleanEmail;
        _localId = data['localId'] as String?;
        _isRestVerified = false;
        await _saveTokens(_idToken, _currentEmail, _localId);

        // Send official verification email via REST
        if (_idToken != null) {
          await _sendEmailVerificationRest(_idToken!);
        }
      } catch (e) {
        if (e is String) rethrow;
        throw 'حدث خطأ أثناء إنشاء الحساب: $e';
      }
    }
  }

  /// Log in with existing Email and Password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    bool sdkSuccess = false;

    // 1. Try Firebase Auth SDK
    try {
      final a = _auth;
      if (a != null) {
        final credential = await a.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        sdkSuccess = true;
        _currentEmail = cleanEmail;
        _localId = credential.user?.uid;
        _idToken = await credential.user?.getIdToken();
        _isRestVerified = credential.user?.emailVerified ?? false;
        await _saveTokens(_idToken, _currentEmail, _localId);
      }
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      debugPrint('SDK signIn exception (will fallback to REST): $e');
    }

    // 2. Fallback to Firebase REST API
    if (!sdkSuccess) {
      try {
        final res = await http.post(
          Uri.parse('$_identityToolkitBase:signInWithPassword?key=$_firebaseApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            'password': password,
            'returnSecureToken': true,
          }),
        );

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 200) {
          throw _parseRestError(data);
        }

        _idToken = data['idToken'] as String?;
        _currentEmail = cleanEmail;
        _localId = data['localId'] as String?;
        await _saveTokens(_idToken, _currentEmail, _localId);

        // Check verification status from REST
        if (_idToken != null) {
          _isRestVerified = await _lookupEmailVerifiedFromRest(_idToken!);
        }
      } catch (e) {
        if (e is String) rethrow;
        throw 'حدث خطأ أثناء تسجيل الدخول: $e';
      }
    }
  }

  /// Send email verification link to currently signed in user
  Future<void> sendEmailVerification() async {
    bool sent = false;
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        sent = true;
      }
    } catch (e) {
      debugPrint('SDK sendEmailVerification error: $e');
    }

    if (!sent) {
      final token = await _getIdToken();
      if (token != null) {
        await _sendEmailVerificationRest(token);
      } else {
        throw 'تعذر إرسال رابط التفعيل، يرجى إعادة تسجيل الدخول والمحاولة.';
      }
    }
  }

  /// Send password reset email to the specified email address
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    bool sent = false;
    try {
      final a = _auth;
      if (a != null) {
        await a.sendPasswordResetEmail(email: cleanEmail);
        sent = true;
      }
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      debugPrint('SDK password reset failed, trying REST: $e');
    }

    if (!sent) {
      try {
        final res = await http.post(
          Uri.parse('$_identityToolkitBase:sendOobCode?key=$_firebaseApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'requestType': 'PASSWORD_RESET',
            'email': cleanEmail,
          }),
        );

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 200) {
          throw _parseRestError(data);
        }
      } catch (e) {
        if (e is String) rethrow;
        throw 'حدث خطأ أثناء إرسال رابط إعادة تعيين كلمة المرور.';
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _idToken = null;
    _currentEmail = null;
    _localId = null;
    _isRestVerified = false;
    await _clearTokens();
  }

  // ---------------- Private Helpers ----------------

  Future<void> _sendEmailVerificationRest(String idToken) async {
    final res = await http.post(
      Uri.parse('$_identityToolkitBase:sendOobCode?key=$_firebaseApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestType': 'VERIFY_EMAIL',
        'idToken': idToken,
      }),
    );

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw _parseRestError(data);
    }
    debugPrint('✅ Firebase REST sendOobCode VERIFY_EMAIL success');
  }

  Future<bool> _lookupEmailVerifiedFromRest(String idToken) async {
    final res = await http.post(
      Uri.parse('$_identityToolkitBase:lookup?key=$_firebaseApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>?;
    if (users != null && users.isNotEmpty) {
      final userObj = users.first as Map<String, dynamic>;
      return userObj['emailVerified'] == true;
    }
    return false;
  }

  Future<String?> _getIdToken() async {
    if (_idToken != null) return _idToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _idToken = prefs.getString('firebase_id_token');
      _currentEmail = prefs.getString('firebase_user_email');
      _localId = prefs.getString('firebase_local_id');
      return _idToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTokens(String? token, String? email, String? localId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('firebase_id_token', token);
      if (email != null) await prefs.setString('firebase_user_email', email);
      if (localId != null) await prefs.setString('firebase_local_id', localId);
    } catch (_) {}
  }

  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('firebase_id_token');
      await prefs.remove('firebase_user_email');
      await prefs.remove('firebase_local_id');
    } catch (_) {}
  }

  String _parseRestError(Map<String, dynamic> data) {
    final errorObj = data['error'] as Map<String, dynamic>?;
    final message = errorObj?['message'] as String? ?? '';

    if (message.contains('EMAIL_EXISTS')) {
      return 'البريد الإلكتروني مستخدم بالفعل بحساب آخر. يرجى تسجيل الدخول أو استخدام بريد جديد.';
    } else if (message.contains('INVALID_EMAIL')) {
      return 'عنوان البريد الإلكتروني غير صحيح. يرجى كتابة بريدك الإلكتروني الشخصي بشكل سليم.';
    } else if (message.contains('WEAK_PASSWORD')) {
      return 'كلمة المرور ضعيفة جداً. يجب أن تتكون من 6 أرقام أو حروف على الأقل.';
    } else if (message.contains('EMAIL_NOT_FOUND')) {
      return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني. يرجى إنشاء حساب جديد.';
    } else if (message.contains('INVALID_PASSWORD') || message.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'بيانات الدخول غير صحيحة. يرجى التحقق من البريد الإلكتروني وكلمة المرور.';
    } else if (message.contains('USER_DISABLED')) {
      return 'تم تعطيل هذا الحساب من قبل الإدارة.';
    } else if (message.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return 'تم تجاوز عدد المحاولات المسموح بها مؤقتاً. يرجى الانتظار والمحاولة لاحقاً.';
    } else if (message.contains('OPERATION_NOT_ALLOWED')) {
      return 'تسجيل الدخول بالبريد الإلكتروني غير مفعل في خادم التطبيق.';
    }
    return 'حدث خطأ: $message';
  }

  String _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل بحساب آخر. يرجى استخدام بريد جديد أو الانتقال لتسجيل الدخول.';
      case 'invalid-email':
        return 'عنوان البريد الإلكتروني غير صحيح. يرجى إدخال بريد إلكتروني شخصي حقيقي مثل (name@domain.com).';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً، يرجى اختيار كلمة مرور تتكون من 6 أرقام/أحرف على الأقل.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب من قبل الإدارة.';
      case 'user-not-found':
        return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني. يرجى التحقق أو إنشاء حساب جديد.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'invalid-credential':
        return 'بيانات البريد الإلكتروني أو كلمة السر غير صحيحة.';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح بها مؤقتاً. يرجى المحاولة لاحقاً.';
      case 'network-request-failed':
        return 'فشل الاتصال بالشبكة. يرجى التحقق من الاتصال بالإنترنت.';
      default:
        return e.message ?? 'حدث خطأ في عملية التوثيق (${e.code}).';
    }
  }
}
