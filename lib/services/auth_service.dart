import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of user auth status changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if current user is email verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Reload current user profile from Firebase to fetch updated verification status
  Future<User?> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser;
    }
    return null;
  }

  /// Register a new account with Email and Password
  /// and automatically send email verification.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send email verification link
      final user = credential.user;
      if (user != null) {
        try {
          await user.sendEmailVerification();
          debugPrint('✅ Firebase sendEmailVerification success for ${user.email}');
        } catch (e) {
          debugPrint('❌ Firebase sendEmailVerification error: $e');
          throw 'تم إنشاء الحساب في Firebase، ولكن تعذر إرسال رسالة التفعيل: $e';
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع أثناء إنشاء الحساب: $e';
    }
  }

  /// Log in with existing Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع أثناء تسجيل الدخول: $e';
    }
  }

  /// Sign in with SMS OTP Code (Phone Auth)
  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء التحقق من رمز SMS: $e';
    }
  }

  /// Send email verification link to currently signed in user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء إرسال رابط إعادة تعيين كلمة المرور.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// User friendly error translation into Arabic
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
        return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'invalid-credential':
        return 'بيانات البريد الإلكتروني أو كلمة السر غير صحيحة.';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح بها. يرجى المحاولة لاحقاً.';
      case 'network-request-failed':
        return 'فشل الاتصال بالشبكة. يرجى التحقق من الاتصال بالإنترنت.';
      default:
        return e.message ?? 'حدث خطأ في عملية التوثيق (${e.code}).';
    }
  }
}
