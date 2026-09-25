import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/database_helper.dart';
import '../widgets/user_profile_avatar.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // State mode: true = Sign Up, false = Log In
  bool _isSignUpMode = false;

  // Profile picture state
  String? _profileImagePath;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Selections
  String _selectedGender = 'ذكر';
  String _selectedCountryCode = '+964'; // Default Iraq
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
    {'code': '+964', 'name': 'العراق 🇮🇶'},
    {'code': '+966', 'name': 'السعودية 🇸🇦'},
    {'code': '+971', 'name': 'الإمارات 🇦🇪'},
    {'code': '+20', 'name': 'مصر 🇪🇬'},
    {'code': '+962', 'name': 'الأردن 🇯🇴'},
    {'code': '+965', 'name': 'الكويت 🇰🇼'},
    {'code': '+974', 'name': 'قطر 🇶🇦'},
    {'code': '+968', 'name': 'عُمان 🇴🇲'},
    {'code': '+963', 'name': 'سوريا 🇸🇾'},
    {'code': '+961', 'name': 'لبنان 🇱🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _passwordController.addListener(_evalPasswordStrength);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

    if (_isSignUpMode && _selectedBirthDate == null) {
      _showSnackbar('الرجاء اختيار تاريخ الميلاد', isError: true);
      return;
    }

    final isWhatsAppMethod = _tabController.index == 1;

    if (_isSignUpMode) {
      if (isWhatsAppMethod) {
        final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
        final cleanPhone = fullPhone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '').trim();
        final otpCode = (100000 + Random().nextInt(899999)).toString();
        final textMessage = 'رمز التوثيق الخاص بك لتطبيق قضاء الفروض والعبادات هو: $otpCode';
        final encodedMsg = Uri.encodeComponent(textMessage);

        // Launch WhatsApp immediately on user tap to bypass browser popup blocker
        final waUrl = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg');
        try {
          launchUrl(
            waUrl,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
        } catch (_) {}

        _showWhatsAppOtpBottomSheet(fullPhone, initialOtp: otpCode);
      } else {
        // Email registration -> Send OTP verification code to personal email
        final email = _emailController.text.trim();
        final otpCode = (100000 + Random().nextInt(899999)).toString();
        final mailUrl = Uri.parse(
          'mailto:$email?subject=${Uri.encodeComponent('كود تفعيل حساب قضاء الفروض')}&body=${Uri.encodeComponent('رمز التوثيق لتفعيل حسابك في تطبيق قضاء الفروض والعبادات هو: $otpCode')}',
        );
        try {
          launchUrl(
            mailUrl,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
        } catch (_) {}

        _showEmailOtpBottomSheet(email, initialOtp: otpCode);
      }
    } else {
      // Log In Mode for existing users (تسجيل الدخول لمن يمتلك تسجيل مسبق)
      await _completeLogin(authMethod: isWhatsAppMethod ? 'whatsapp' : 'email');
    }
  }

  Future<void> _completeLogin({required String authMethod}) async {
    setState(() => _isLoading = true);

    try {
      final existingProfile = await DatabaseHelper.instance.getUserProfile();
      final fullPhone = _phoneController.text.isNotEmpty
          ? '$_selectedCountryCode${_phoneController.text.trim()}'
          : '';
      final email = _emailController.text.trim();

      final profileData = {
        'name': existingProfile?['name'] ?? (email.isNotEmpty ? email.split('@')[0] : 'المستخدم'),
        'email': email.isNotEmpty ? email : (existingProfile?['email'] ?? ''),
        'phone': fullPhone.isNotEmpty ? fullPhone : (existingProfile?['phone'] ?? ''),
        'auth_method': authMethod,
        'gender': existingProfile?['gender'] ?? 'ذكر',
        'birth_date': existingProfile?['birth_date'] ?? '',
        'country': existingProfile?['country'] ?? _selectedCountry,
        'city': existingProfile?['city'] ?? '',
        'profile_image': existingProfile?['profile_image'] ?? '',
        'created_at': existingProfile?['created_at'] ?? DateTime.now().toIso8601String(),
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

  Future<void> _completeAuthentication({required String authMethod}) async {
    setState(() => _isLoading = true);

    try {
      final String formattedBirthDate = _selectedBirthDate != null
          ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
          : "";

      final fullPhone = _phoneController.text.isNotEmpty
          ? '$_selectedCountryCode${_phoneController.text.trim()}'
          : '';

      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': fullPhone,
        'auth_method': authMethod,
        'gender': _selectedGender,
        'birth_date': formattedBirthDate,
        'country': _selectedCountry,
        'city': _cityController.text.trim(),
        'profile_image': _profileImagePath ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      await DatabaseHelper.instance.saveUserProfile(profileData);

      if (!mounted) return;

      _showSnackbar('تم إنشاء الحساب والدخول بنجاح! أهلاً بك 🎉');

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
        _showSnackbar('حدث خطأ أثناء حفظ الحساب: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailOtpBottomSheet(String email, {required String initialOtp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmailOtpModal(
        email: email,
        initialOtp: initialOtp,
        onVerified: () {
          Navigator.pop(context);
          _completeAuthentication(authMethod: 'email');
        },
      ),
    );
  }

  void _showWhatsAppOtpBottomSheet(String fullPhone, {required String initialOtp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WhatsAppOtpModal(
        phoneNumber: fullPhone,
        initialOtp: initialOtp,
        onVerified: () {
          Navigator.pop(context);
          _completeAuthentication(authMethod: 'whatsapp');
        },
      ),
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
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isSignUpMode) ...[
                              _buildPersonalDataSection(),
                              const SizedBox(height: 20),
                            ],
                            _buildAuthTabsSection(),
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                            const SizedBox(height: 16),
                            _buildToggleModeButton(),
                            const SizedBox(height: 20),
                          ],
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
              Icons.app_registration_rounded,
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
                ? 'قم بتسجيل بياناتك لمتابعة صلواتك وصيامك وعباداتك بسهولة'
                : 'أهلاً بعودتك، أدخل بياناتك للدخول إلى حسابك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthModeCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF0F766E),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(
            icon: Icon(_isSignUpMode ? Icons.email_outlined : Icons.person_outline, size: 20),
            text: _isSignUpMode ? 'البريد الإلكتروني' : 'اسم المستخدم / البريد',
          ),
          Tab(
            icon: const Icon(Icons.phone_android_outlined, size: 20),
            text: _isSignUpMode ? 'الواتساب (الهاتف)' : 'رقم الهاتف',
          ),
        ],
        onTap: (index) {
          setState(() {});
        },
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
                  radius: 46,
                  showEditBadge: true,
                  onTap: _showImageSourcePicker,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showImageSourcePicker,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF0F766E)),
                  label: const Text(
                    'اضغط لتحديد الصورة الشخصية',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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

  Widget _buildAuthTabsSection() {
    final isEmailTab = _tabController.index == 0;

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
            children: [
              Icon(
                isEmailTab ? Icons.mark_email_read_outlined : Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF0F766E),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isEmailTab
                    ? (_isSignUpMode ? 'توثيق البريد الإلكتروني' : 'تسجيل الدخول بالبريد الإلكتروني')
                    : (_isSignUpMode ? 'توثيق رقم الهاتف عبر الواتساب' : 'تسجيل الدخول برقم الهاتف'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          if (isEmailTab) ...[
            // Username / Email Input
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _isSignUpMode ? 'البريد الإلكتروني *' : 'اسم المستخدم أو البريد الإلكتروني *',
                hintText: _isSignUpMode ? 'example@domain.com' : 'أدخل اسم المستخدم أو البريد الإلكتروني',
                prefixIcon: Icon(_isSignUpMode ? Icons.email_outlined : Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              validator: (val) {
                if (_tabController.index == 0) {
                  if (val == null || val.trim().isEmpty) {
                    return _isSignUpMode
                        ? 'الرجاء إدخال البريد الإلكتروني'
                        : 'الرجاء إدخال اسم المستخدم أو البريد الإلكتروني';
                  }
                  if (_isSignUpMode && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                    return 'الرجاء إدخال بريد إلكتروني صحيح';
                  }
                  if (!_isSignUpMode && val.trim().length < 3) {
                    return 'اسم المستخدم أو البريد قصير جداً';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password Input
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
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
                if (_tabController.index == 0) {
                  if (val == null || val.isEmpty) {
                    return 'الرجاء إدخال كلمة السر';
                  }
                  if (val.length < 6) {
                    return 'كلمة السر يجب أن تكون من 6 خانات على الأقل';
                  }
                }
                return null;
              },
            ),

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
                  if (_tabController.index == 0 && _isSignUpMode) {
                    if (val == null || val != _passwordController.text) {
                      return 'كلمات السر غير متطابقة';
                    }
                  }
                  return null;
                },
              ),
            ],
          ] else ...[
            // WhatsApp / Phone Input
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCountryCode,
                    decoration: InputDecoration(
                      labelText: 'رمز الدولة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    ),
                    items: _countries.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text("${c['code']} ${c['name']!.split(' ')[1]}", style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCountryCode = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف *',
                      hintText: '7701234567',
                      prefixIcon: const Icon(Icons.phone_android_outlined, color: Color(0xFF25D366)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (val) {
                      if (_tabController.index == 1) {
                        if (val == null || val.trim().isEmpty) {
                          return 'الرجاء إدخال رقم الهاتف';
                        }
                        if (val.trim().length < 7) {
                          return 'رقم الهاتف قصير جداً';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!_isSignUpMode) ...[
              // Password input for logging in via phone
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
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
                  if (_tabController.index == 1 && !_isSignUpMode) {
                    if (val == null || val.isEmpty) {
                      return 'الرجاء إدخال كلمة السر';
                    }
                    if (val.length < 6) {
                      return 'كلمة السر يجب أن تكون من 6 خانات على الأقل';
                    }
                  }
                  return null;
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سيتم إرسال رمز التحقق OTP المكون من 6 أرقام مباشرة إلى حسابك في الواتساب.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF064E3B), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isWhatsApp = _tabController.index == 1;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isWhatsApp ? const Color(0xFF25D366) : const Color(0xFF0F766E),
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
                    _isSignUpMode
                        ? (isWhatsApp ? Icons.mark_chat_unread_outlined : Icons.mark_email_read_outlined)
                        : Icons.login_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isSignUpMode
                        ? (isWhatsApp ? 'إرسال رمز التوثيق بالواتساب' : 'إرسال كود التفعيل للإيميل')
                        : 'تسجيل الدخول',
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

/// Modal for WhatsApp OTP input & simulated timer
class _WhatsAppOtpModal extends StatefulWidget {
  final String phoneNumber;
  final String? initialOtp;
  final VoidCallback onVerified;

  const _WhatsAppOtpModal({
    required this.phoneNumber,
    this.initialOtp,
    required this.onVerified,
  });

  @override
  State<_WhatsAppOtpModal> createState() => _WhatsAppOtpModalState();
}

class _WhatsAppOtpModalState extends State<_WhatsAppOtpModal> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isVerifying = false;
  late String _otpCode;

  @override
  void initState() {
    super.initState();
    _otpCode = widget.initialOtp ?? (100000 + Random().nextInt(899999)).toString();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _launchWhatsAppDirectly() async {
    final cleanPhone = widget.phoneNumber.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '').trim();
    final textMessage = 'رمز التوثيق الخاص بك لتطبيق قضاء الفروض والعبادات هو: $_otpCode';
    final encodedMsg = Uri.encodeComponent(textMessage);

    final apiWaUrl = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg');
    final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    try {
      await launchUrl(
        apiWaUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      try {
        await launchUrl(
          waUrl,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } catch (e) {
        debugPrint('Error launching WhatsApp URL: $e');
      }
    }
  }

  void _autoFillOtp() {
    for (int i = 0; i < 6; i++) {
      if (i < _otpCode.length) {
        _otpControllers[i].text = _otpCode[i];
      }
    }
    setState(() {});
    _verifyOtpCode();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _verifyOtpCode() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء إدخال الرمز المكون من 6 أرقام كاملة', textAlign: TextAlign.center),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      widget.onVerified();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'تأكيد رمز الواتساب',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 6),
            Text(
              'جاري إرسال كود التحقق OTP إلى الرقم:\n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Direct launch WhatsApp button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _launchWhatsAppDirectly,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'فتح تطبيق الواتساب لإرسال الرسالة 💬',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // OTP Display & Auto fill helper banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_outlined, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal', color: Color(0xFF166534)),
                        children: [
                          const TextSpan(text: 'رمز التوثيق: '),
                          TextSpan(
                            text: _otpCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _autoFillOtp,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'تعبئة تلقائية ⚡',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // OTP 6 digit inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                        _verifyOtpCode();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Timer & Resend
            if (_secondsRemaining > 0)
              Text(
                'إعادة طلب الرمز خلال: $_secondsRemaining ثانية',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              )
            else
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _otpCode = (100000 + Random().nextInt(899999)).toString();
                  });
                  _startTimer();
                  _launchWhatsAppDirectly();
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF25D366)),
                label: const Text(
                  'إعادة إرسال كود التحقق عبر الواتساب',
                  style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isVerifying ? null : _verifyOtpCode,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تأكيد وتفعيل الحساب',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal for Email OTP input & verification timer
class _EmailOtpModal extends StatefulWidget {
  final String email;
  final String? initialOtp;
  final VoidCallback onVerified;

  const _EmailOtpModal({
    required this.email,
    this.initialOtp,
    required this.onVerified,
  });

  @override
  State<_EmailOtpModal> createState() => _EmailOtpModalState();
}

class _EmailOtpModalState extends State<_EmailOtpModal> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isVerifying = false;
  late String _otpCode;

  @override
  void initState() {
    super.initState();
    _otpCode = widget.initialOtp ?? (100000 + Random().nextInt(899999)).toString();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _launchEmailAppDirectly() async {
    final mailUrl = Uri.parse(
      'mailto:${widget.email}?subject=${Uri.encodeComponent('كود تفعيل حساب قضاء الفروض')}&body=${Uri.encodeComponent('رمز التوثيق لتفعيل حسابك هو: $_otpCode')}',
    );
    try {
      await launchUrl(
        mailUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Error launching Email client: $e');
    }
  }

  void _autoFillOtp() {
    for (int i = 0; i < 6; i++) {
      if (i < _otpCode.length) {
        _otpControllers[i].text = _otpCode[i];
      }
    }
    setState(() {});
    _verifyOtpCode();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _verifyOtpCode() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء إدخال الرمز المكون من 6 أرقام كاملة', textAlign: TextAlign.center),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      widget.onVerified();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFCCFBF1),
              child: Icon(Icons.mark_email_read_outlined, color: Color(0xFF0F766E), size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'تأكيد وتفعيل البريد الإلكتروني',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 6),
            Text(
              'تم إرسال كود التفعيل المكون من 6 أرقام إلى بريدك الشخصي:\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Open Email app button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _launchEmailAppDirectly,
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text(
                'فتح تطبيق البريد الإلكتروني 📧',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // OTP Display & Auto fill helper banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal', color: Color(0xFF166534)),
                        children: [
                          const TextSpan(text: 'كود التفعيل: '),
                          TextSpan(
                            text: _otpCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _autoFillOtp,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'تعبئة تلقائية ⚡',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // OTP 6 digit inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                        _verifyOtpCode();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Timer & Resend
            if (_secondsRemaining > 0)
              Text(
                'إعادة طلب الرمز خلال: $_secondsRemaining ثانية',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              )
            else
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _otpCode = (100000 + Random().nextInt(899999)).toString();
                  });
                  _startTimer();
                  _launchEmailAppDirectly();
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF0F766E)),
                label: const Text(
                  'إعادة إرسال كود التفعيل إلى البريد',
                  style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isVerifying ? null : _verifyOtpCode,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تأكيد وتفعيل الحساب',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
