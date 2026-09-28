import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../widgets/user_profile_avatar.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // State mode: true = Sign Up, false = Log In
  bool _isSignUpMode = false;

  // Profile picture state
  String? _profileImagePath;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Selections
  String _selectedGender = 'ذكر';
  String _selectedCountry = 'العراق';
  DateTime? _selectedBirthDate;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Password strength calculation
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  final List<Map<String, String>> _countries = [
    {'name': 'العراق 🇮🇶'},
    {'name': 'السعودية 🇸🇦'},
    {'name': 'الإمارات 🇦🇪'},
    {'name': 'مصر 🇪🇬'},
    {'name': 'الأردن 🇯🇴'},
    {'name': 'الكويت 🇰🇼'},
    {'name': 'قطر 🇶🇦'},
    {'name': 'عُمان 🇴🇲'},
    {'name': 'سوريا 🇸🇾'},
    {'name': 'لبنان 🇱🇧'},
    {'name': 'أخرى 🌍'},
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_evalPasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _evalPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    double strength = 0;
    if (password.length >= 6) strength += 0.3;
    if (password.length >= 10) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password) || RegExp(r'[a-z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;

    String text = 'ضعيفة جداً';
    Color color = Colors.red;
    if (strength >= 0.8) {
      text = 'قوية جداً';
      color = const Color(0xFF10B981);
    } else if (strength >= 0.5) {
      text = 'متوسطة';
      color = const Color(0xFFF59E0B);
    } else if (strength >= 0.3) {
      text = 'مقبولة';
      color = Colors.orangeAccent;
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F766E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Strict email format validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,10}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackbar('يرجى إدخال عنوان بريد إلكتروني شخصي حقيقي (مثل: name@domain.com)', isError: true);
      return;
    }

    if (_isSignUpMode) {
      if (_selectedBirthDate == null) {
        _showSnackbar('الرجاء اختيار تاريخ الميلاد', isError: true);
        return;
      }

      setState(() => _isLoading = true);
      try {
        // Register strictly through official Email Verification
        await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Show Email Verification Dialog (waiting for user to verify via official email)
        _showEmailVerificationDialog(email);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackbar(e.toString(), isError: true);
        }
      }
    } else {
      // Log In Mode: Authenticate email & password
      await _completeLogin();
    }
  }

  Future<void> _completeLogin() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _showSnackbar('الرجاء إدخال البريد الإلكتروني وكلمة السر', isError: true);
        return;
      }

      try {
        await AuthService.instance.signInWithEmail(
          email: email,
          password: password,
        );
      } catch (e) {
        if (mounted) {
          _showSnackbar(e.toString(), isError: true);
        }
        return;
      }

      // Check whether user's email has been verified
      final isVerified = await AuthService.instance.checkIsEmailVerified();
      if (!isVerified) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackbar('بريدك الإلكتروني غير مفعّل بعد! يرجى تفعيل حسابك أولاً عبر الرسالة المرسلة لبريدك.', isError: true);
          _showEmailVerificationDialog(email);
        }
        return;
      }

      final existingProfile = await DatabaseHelper.instance.getUserProfile();

      final profileData = {
        'name': existingProfile?['name'] ?? (email.isNotEmpty ? email.split('@')[0] : 'المستخدم'),
        'email': email,
        'phone': existingProfile?['phone'] ?? '',
        'auth_method': 'email',
        'gender': existingProfile?['gender'] ?? 'ذكر',
        'birth_date': existingProfile?['birth_date'] ?? '',
        'country': existingProfile?['country'] ?? _selectedCountry,
        'city': existingProfile?['city'] ?? '',
        'profile_image': existingProfile?['profile_image'] ?? '',
        'created_at': existingProfile?['created_at'] ?? DateTime.now().toIso8601String(),
        'is_logged_in': 1,
      };

      await DatabaseHelper.instance.saveUserProfile(profileData);

      if (!mounted) return;

      _showSnackbar('تم تسجيل الدخول بنجاح! أهلاً بعودتك 🎉');

      final prayer = await DatabaseHelper.instance.getObligation('PRAYER');
      final isFirstTime = (prayer == null || (prayer['total_required'] ?? 0) <= 0);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isFirstTime ? const OnboardingScreen() : const HomeScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackbar('حدث خطأ أثناء تسجيل الدخول: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: const [
                    Icon(Icons.lock_reset_outlined, color: Color(0xFF0F766E), size: 24),
                    SizedBox(width: 8),
                    Text('استعادة كلمة السر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أدخل عنوان بريدك الإلكتروني المسجل لإرسال رابط إعادة تعيين كلمة المرور إليه:',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني الشخصي',
                        hintText: 'example@domain.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSending
                        ? null
                        : () async {
                            final targetEmail = emailController.text.trim().toLowerCase();
                            if (targetEmail.isEmpty || !targetEmail.contains('@')) {
                              _showSnackbar('يرجى إدخال بريد إلكتروني صحيح', isError: true);
                              return;
                            }
                            setDialogState(() => isSending = true);
                            try {
                              await AuthService.instance.sendPasswordResetEmail(targetEmail);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _showSnackbar('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح 🎉');
                            } catch (e) {
                              setDialogState(() => isSending = false);
                              _showSnackbar(e.toString(), isError: true);
                            }
                          },
                    child: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('إرسال الرابط'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeAuthentication({required String authMethod}) async {
    setState(() => _isLoading = true);

    try {
      final String formattedBirthDate = _selectedBirthDate != null
          ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
          : "";

      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': '',
        'auth_method': authMethod,
        'gender': _selectedGender,
        'birth_date': formattedBirthDate,
        'country': _selectedCountry,
        'city': _cityController.text.trim(),
        'profile_image': _profileImagePath ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'is_logged_in': 1,
      };

      await DatabaseHelper.instance.saveUserProfile(profileData);

      if (!mounted) return;

      _showSnackbar('تم إنشاء الحساب وتأكيد البريد الإلكتروني بنجاح! أهلاً بك 🎉');

      final prayer = await DatabaseHelper.instance.getObligation('PRAYER');
      final isFirstTime = (prayer == null || (prayer['total_required'] ?? 0) <= 0);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isFirstTime ? const OnboardingScreen() : const HomeScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackbar('حدث خطأ أثناء حفظ بيانات الحساب: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailVerificationDialog(String email) {
    bool isChecking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: false,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  title: Row(
                    children: const [
                      Icon(Icons.mark_email_read_outlined, color: Color(0xFF0F766E), size: 28),
                      SizedBox(width: 10),
                      Text('تفعيل البريد الإلكتروني', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تم إرسال رسالة تفعيل رسمية إلى بريدك الإلكتروني الشخصي:',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '📌 يرجى فتح بريدك الإلكتروني والضغط على رابط التفعيل المرفق بالرسالة لتأكيد ملكيتك للبريد قبل التسجيل.\n\nتأكد من فحص مجلد "الرسائل غير المرغوب فيها" (Spam / Junk) إذا لم تجد الرسالة في صندوق الوارد.',
                        style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.5),
                      ),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            onPressed: isChecking
                                ? null
                                : () async {
                                    setDialogState(() => isChecking = true);
                                    try {
                                      final isVerified = await AuthService.instance.checkIsEmailVerified();
                                      if (isVerified) {
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (_isSignUpMode) {
                                          _completeAuthentication(authMethod: 'email');
                                        } else {
                                          _completeLogin();
                                        }
                                      } else {
                                        setDialogState(() => isChecking = false);
                                        _showSnackbar(
                                          'لم يتم الضغط على رابط التفعيل بعد! يرجى فتح البريد والضغط على رابط التفعيل ثم الضغط هنا مجدداً.',
                                          isError: true,
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isChecking = false);
                                      _showSnackbar('حدث خطأ أثناء التحقق: $e', isError: true);
                                    }
                                  },
                            icon: isChecking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.verified_user_outlined, size: 20),
                            label: const Text(
                              'تأكيد وتفعيل الحساب (التحقق الآن)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(color: Color(0xFFD97706)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  try {
                                    await AuthService.instance.sendEmailVerification();
                                    _showSnackbar('تم إعادة إرسال رابط التفعيل إلى بريدك الإلكتروني بنجاح.');
                                  } catch (e) {
                                    _showSnackbar('تعذر إعادة الإرسال: $e', isError: true);
                                  }
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('إعادة الإرسال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                  side: const BorderSide(color: Color(0xFF0F766E)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  final mailUrl = Uri.parse('mailto:$email');
                                  try {
                                    launchUrl(mailUrl, mode: LaunchMode.externalApplication);
                                  } catch (_) {}
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('فتح البريد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'تعديل البريد الإلكتروني / إلغاء',
                            style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      _buildAuthModeCard(),
                      const SizedBox(height: 18),
                      AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (_isSignUpMode) ...[
                                _buildPersonalDataSection(),
                                const SizedBox(height: 18),
                              ],
                              _buildCredentialsSection(),
                              const SizedBox(height: 24),
                              _buildSubmitButton(),
                              const SizedBox(height: 16),
                              _buildToggleModeButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD97706), width: 2),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 40,
              color: Color(0xFFFDE68A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isSignUpMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSignUpMode
                ? 'التسجيل متاح حصرياً عبر البريد الإلكتروني الرسمي مع التحقق'
                : 'أهلاً بعودتك، سجّل الدخول باستخدام بريدك الإلكتروني المفعّل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_isSignUpMode) setState(() => _isSignUpMode = false);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSignUpMode ? const Color(0xFF0F766E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !_isSignUpMode ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () {
                if (!_isSignUpMode) setState(() => _isSignUpMode = true);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSignUpMode ? const Color(0xFF0F766E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isSignUpMode ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (kIsWeb || file.path == null) {
          if (file.bytes != null) {
            final base64Str = 'data:image/png;base64,${base64Encode(file.bytes!)}';
            setState(() {
              _profileImagePath = base64Str;
            });
          }
        } else {
          final savedPath = await _savePickedImage(file.path!);
          setState(() {
            _profileImagePath = savedPath;
          });
        }
      }
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء اختيار الصورة: $e', isError: true);
    }
  }

  Future<String> _savePickedImage(String originalPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ext = p.extension(originalPath).isNotEmpty ? p.extension(originalPath) : '.jpg';
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedFile = await File(originalPath).copy(p.join(appDir.path, fileName));
      return savedFile.path;
    } catch (e) {
      return originalPath;
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final List<String> presetEmojis = [
          '👨', '👩', '🧔', '🧕', '👳‍♂️', '👤', '🕌', '📿', '🌟', '🤲', '🕋', '🕊️', '🌿', '🌙'
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختر الصورة الشخصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF0F766E)),
                  ),
                  title: const Text('اختيار صورة من الجهاز / المعرض', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('اختر صورة ملائمة من ملفاتك', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                const Divider(height: 20),
                const Text(
                  'أو اختر رمزاً تعبيرياً:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetEmojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final emoji = presetEmojis[idx];
                      final isSelected = _profileImagePath == 'emoji:$emoji';
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _profileImagePath = 'emoji:$emoji';
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.15) : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 26)),
                        ),
                      );
                    },
                  ),
                ),
                if (_profileImagePath != null && _profileImagePath!.isNotEmpty) ...[
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('إزالة الصورة الحالية', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () {
                      setState(() {
                        _profileImagePath = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalDataSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, color: Color(0xFF0F766E), size: 22),
              SizedBox(width: 8),
              Text(
                'البيانات الشخصية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Profile Picture Picker Selector
          Center(
            child: Column(
              children: [
                UserProfileAvatar(
                  imagePath: _profileImagePath,
                  gender: _selectedGender,
                  radius: 44,
                  showEditBadge: true,
                  onTap: _showImageSourcePicker,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showImageSourcePicker,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF0F766E)),
                  label: const Text(
                    'تحديد الصورة الشخصية',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Full Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'الاسم الكامل *',
              hintText: 'مثال: أحمد محمد علي',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'الرجاء إدخال الاسم الكامل';
              }
              if (val.trim().length < 3) {
                return 'الاسم يجب أن يكون من 3 حروف على الأقل';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Gender Selection
          const Text(
            'الجنس *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderChoiceCard('ذكر', '👨', _selectedGender == 'ذكر'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderChoiceCard('أنثى', '👩', _selectedGender == 'أنثى'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Birth Date Picker
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF0F766E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ الميلاد *',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedBirthDate != null
                              ? "${_selectedBirthDate!.year}/${_selectedBirthDate!.month}/${_selectedBirthDate!.day} (${DateTime.now().year - _selectedBirthDate!.year} سنة)"
                              : 'اضغط لاختيار تاريخ الميلاد',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedBirthDate != null ? FontWeight.bold : FontWeight.normal,
                            color: _selectedBirthDate != null ? Colors.black87 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Country & City
          Row(
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'البلد',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                  items: _countries.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['name']!.split(' ')[0],
                      child: Text(c['name']!, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCountry = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'المدينة',
                    hintText: 'بغداد/الرياض..',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChoiceCard(String label, String emoji, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedGender = label),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.12) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.mark_email_read_outlined, color: Color(0xFF0F766E), size: 22),
              SizedBox(width: 8),
              Text(
                'بيانات الدخول بالبريد الإلكتروني الرسمي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Notice banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0F766E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSignUpMode
                        ? 'يُشترط استخدام بريد حقيقي؛ سيتم إرسال رسالة تفعيل قبل إتمام التسجيل.'
                        : 'أدخل بريدك الإلكتروني المفعّل مسبقاً للدخول.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Email Input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني الشخصي الرسمي *',
              hintText: 'example@domain.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'الرجاء إدخال البريد الإلكتروني';
              }
              final emailTrimmed = val.trim().toLowerCase();
              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,10}$');
              if (!emailRegex.hasMatch(emailTrimmed)) {
                return 'الرجاء إدخال بريد إلكتروني شخصي حقيقي (مثل name@domain.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password Input
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'كلمة السر *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'الرجاء إدخال كلمة السر';
              }
              if (val.length < 6) {
                return 'كلمة السر يجب أن تكون من 6 خانات على الأقل';
              }
              return null;
            },
          ),

          if (!_isSignUpMode) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                  'نسيت كلمة السر؟',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          if (_isSignUpMode && _passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey.shade200,
                      color: _passwordStrengthColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'قوة كلمة السر: $_passwordStrengthText',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _passwordStrengthColor,
                  ),
                ),
              ],
            ),
          ],

          if (_isSignUpMode) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة السر *',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              validator: (val) {
                if (_isSignUpMode) {
                  if (val == null || val != _passwordController.text) {
                    return 'كلمات السر غير متطابقة';
                  }
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSignUpMode ? Icons.mark_email_read_outlined : Icons.login_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isSignUpMode ? 'إنشاء حساب وإرسال رابط التفعيل ✉️' : 'تسجيل الدخول',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleModeButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isSignUpMode = !_isSignUpMode;
        });
      },
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
          children: [
            TextSpan(
              text: _isSignUpMode ? 'لديك حساب بالفعل؟ ' : 'ليس لديك حساب؟ ',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            TextSpan(
              text: _isSignUpMode ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
