import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/database_helper.dart';
import '../widgets/user_profile_avatar.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseHelper.instance.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت أربك من تسجيل الخروج من الحساب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.logoutUserProfile();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F766E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
            : _userProfile == null
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildAvatarHeader(),
                        const SizedBox(height: 20),
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'لم يتم العثور على حساب مسجل',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('تسجيل الدخول / إنشاء حساب'),
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
        String imagePath = '';
        if (kIsWeb || file.path == null) {
          if (file.bytes != null) {
            imagePath = 'data:image/png;base64,${base64Encode(file.bytes!)}';
          }
        } else {
          imagePath = await _savePickedImage(file.path!);
        }

        if (imagePath.isNotEmpty) {
          await DatabaseHelper.instance.updateUserProfileImage(imagePath);
          _loadProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تغيير الصورة: $e')),
        );
      }
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

        final currentImg = _userProfile?['profile_image'];

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
                  'تغيير الصورة الشخصية',
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
                  subtitle: const Text('اختر صورة جديدة من ملفاتك', style: TextStyle(fontSize: 12)),
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
                      final isSelected = currentImg == 'emoji:$emoji';
                      return InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await DatabaseHelper.instance.updateUserProfileImage('emoji:$emoji');
                          _loadProfile();
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
                if (currentImg != null && currentImg.toString().isNotEmpty) ...[
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('إزالة الصورة الحالية', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      Navigator.pop(context);
                      await DatabaseHelper.instance.updateUserProfileImage('');
                      _loadProfile();
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

  Widget _buildAvatarHeader() {
    final name = _userProfile!['name'] ?? 'المستخدم';
    final gender = _userProfile!['gender'] ?? 'ذكر';
    final method = _userProfile!['auth_method'] ?? 'email';
    final profileImage = _userProfile!['profile_image'];

    final isWhatsApp = method == 'whatsapp';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          UserProfileAvatar(
            imagePath: profileImage,
            gender: gender,
            radius: 46,
            showEditBadge: true,
            onTap: _showImageSourcePicker,
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isWhatsApp ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWhatsApp ? const Color(0xFF25D366) : const Color(0xFF0284C7),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWhatsApp ? Icons.chat_bubble_outline : Icons.email,
                  size: 16,
                  color: isWhatsApp ? const Color(0xFF15803D) : const Color(0xFF0369A1),
                ),
                const SizedBox(width: 6),
                Text(
                  isWhatsApp ? 'موثق عبر الواتساب' : 'موثق عبر البريد الإلكتروني',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isWhatsApp ? const Color(0xFF15803D) : const Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final email = _userProfile!['email'];
    final phone = _userProfile!['phone'];
    final gender = _userProfile!['gender'] ?? 'ذكر';
    final birthDate = _userProfile!['birth_date'] ?? '';
    final country = _userProfile!['country'] ?? '';
    final city = _userProfile!['city'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفاصيل الحساب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
          const Divider(height: 24),
          if (email != null && email.toString().isNotEmpty)
            _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', email),
          if (phone != null && phone.toString().isNotEmpty)
            _buildInfoRow(Icons.phone_android_outlined, 'رقم الهاتف (الواتساب)', phone),
          _buildInfoRow(Icons.person_outline, 'الجنس', gender),
          if (birthDate.isNotEmpty)
            _buildInfoRow(Icons.cake_outlined, 'تاريخ الميلاد', birthDate),
          if (country.isNotEmpty || city.isNotEmpty)
            _buildInfoRow(Icons.location_on_outlined, 'الموقع', '$country ${city.isNotEmpty ? "- $city" : ""}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade400, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text(
          'تسجيل الخروج من الحساب',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
