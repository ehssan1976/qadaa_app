import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../widgets/app_logo_icon.dart';
import '../widgets/user_profile_avatar.dart';
import 'about_screen.dart';
import 'auth_screen.dart';
import 'backup_screen.dart';
import 'debts_screen.dart';
import 'devotions_screen.dart';
import 'khums_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'will_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _prayerData;
  Map<String, dynamic>? _fastingData;
  Map<String, dynamic>? _userProfile;
  Map<String, int> _todayActionCounts = {};
  bool _isLoading = true;
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prayers = await DatabaseHelper.instance.getObligation('PRAYER');
      final fasting = await DatabaseHelper.instance.getObligation('FASTING');
      final todayCounts =
          await DatabaseHelper.instance.getTodayActionCounts();
      final profile = await DatabaseHelper.instance.getUserProfile();
      if (mounted) {
        setState(() {
          _prayerData = prayers;
          _fastingData = fasting;
          _todayActionCounts = todayCounts;
          _userProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading qadaa data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _triggerFeedback() {
    HapticFeedback.lightImpact();
  }

  void _showSuccessSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showEditTotalDialog(
    String type,
    String title,
    int currentVal,
  ) async {
    final controller = TextEditingController(text: currentVal.toString());
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('تعديل مدة $title المطلوبة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل إجمالي عدد الأيام المطلوبة لقضاء $title:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: type == 'PRAYER'
                      ? 'عدد أيام الصلوات'
                      : 'عدد أيام الصيام',
                  suffixText: 'يوم',
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
              onPressed: () async {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val >= 0) {
                  await DatabaseHelper.instance.updateTotalRequired(type, val);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData();
                  if (mounted) _showSuccessSnackbar('تم تحديث مدة $title بنجاح');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Row(
            children: [
              AppLogoIcon(size: 28),
              SizedBox(width: 10),
              Text('تطبيق قضاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'قائمة الحساب والخدمات',
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
                if (index == 5) {
                  _loadData();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                const PopupMenuItem<int>(
                  value: 5,
                  child: Row(
                    children: [
                      Icon(Icons.person_pin_outlined, color: Color(0xFF0F766E)),
                      SizedBox(width: 10),
                      Text('الحساب والتوثيق', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<int>(
                  value: 6,
                  child: Row(
                    children: [
                      Icon(Icons.backup_outlined, color: Color(0xFF0F766E)),
                      SizedBox(width: 10),
                      Text('النسخ الاحتياطي والبيانات', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<int>(
                  value: 7,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF0F766E)),
                      SizedBox(width: 10),
                      Text('عن التطبيق والإهداء', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeDashboard(),
            const DebtsScreen(),
            const WillScreen(),
            const KhumsScreen(),
            const DevotionsScreen(),
            _userProfile != null ? const ProfileScreen() : const AuthScreen(),
            const BackupScreen(),
            const AboutScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex < 5 ? _currentIndex : 0,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              _loadData();
            }
          },
          elevation: 4,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.mosque_outlined),
              selectedIcon: Icon(Icons.mosque, color: Color(0xFF0F766E)),
              label: 'القضاء',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF0F766E)),
              label: 'سجل الديون',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu, color: Color(0xFF0F766E)),
              label: 'الوصية والتركة',
            ),
            NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium, color: Color(0xFF0F766E)),
              label: 'حساب الخمس',
            ),
            NavigationDestination(
              icon: Icon(Icons.touch_app_outlined),
              selectedIcon: Icon(Icons.touch_app, color: Color(0xFF0F766E)),
              label: 'المسبحة',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
      );
    }

    final totalPrayersRequired = _prayerData?['total_required'] ?? 0;
    final fajr = _prayerData?['completed_fajr'] ?? 0;
    final dhuhr = _prayerData?['completed_dhuhr'] ?? 0;
    final asr = _prayerData?['completed_asr'] ?? 0;
    final maghrib = _prayerData?['completed_maghrib'] ?? 0;
    final isha = _prayerData?['completed_isha'] ?? 0;
    final totalCompletedPrayers = fajr + dhuhr + asr + maghrib + isha;
    final totalPrayersTarget = totalPrayersRequired * 5;
    final prayerProgress = totalPrayersTarget > 0
        ? (totalCompletedPrayers / totalPrayersTarget).clamp(0.0, 1.0)
        : 0.0;

    final fullCompletedPrayerDays = [fajr, dhuhr, asr, maghrib, isha]
        .reduce((a, b) => a < b ? a : b);

    final totalFastingRequired = _fastingData?['total_required'] ?? 0;
    final completedFasting = _fastingData?['completed_fasting'] ?? 0;
    final fastingProgress = totalFastingRequired > 0
        ? (completedFasting / totalFastingRequired).clamp(0.0, 1.0)
        : 0.0;

    final remainingPrayerDays =
        (totalPrayersRequired - fullCompletedPrayerDays).clamp(
          0,
          totalPrayersRequired,
        );
    final remainingFastingDays = (totalFastingRequired - completedFasting)
        .clamp(0, totalFastingRequired);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'قضاء الفروض والعبادات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: _userProfile != null
                ? UserProfileAvatar(
                    imagePath: _userProfile!['profile_image'],
                    gender: _userProfile!['gender'],
                    radius: 13,
                  )
                : const Icon(
                    Icons.account_circle,
                    size: 26,
                    color: Color(0xFF0F766E),
                  ),
            tooltip: _userProfile != null ? 'الملف الشخصي' : 'تسجيل الدخول / إنشاء حساب',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _userProfile != null ? const ProfileScreen() : const AuthScreen(),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: 'تعديل خطة القضاء الإجمالية',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingScreen(isEditing: true),
                ),
              );
              if (res == true) _loadData();
            },
          ),
        ],
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildUserAccountHeaderCard(),
            const SizedBox(height: 12),
            _buildDedicationCard(),
            const SizedBox(height: 12),
            _buildEstimatedCompletionCard(
              remainingPrayerDays: remainingPrayerDays,
              remainingFastingDays: remainingFastingDays,
            ),
            const SizedBox(height: 16),
            _buildPrayerSection(
              totalPrayersRequired: totalPrayersRequired,
              completedCount: totalCompletedPrayers,
              targetCount: totalPrayersTarget,
              progress: prayerProgress,
              fajr: fajr,
              dhuhr: dhuhr,
              asr: asr,
              maghrib: maghrib,
              isha: isha,
            ),
            const SizedBox(height: 16),
            _buildFastingCard(
              totalRequired: totalFastingRequired,
              completed: completedFasting,
              progress: fastingProgress,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }



  Widget _buildUserAccountHeaderCard() {
    if (_userProfile != null) {
      final name = _userProfile!['name'] ?? 'المستخدم';
      final authMethod = _userProfile!['auth_method'] ?? 'email';
      final gender = _userProfile!['gender'] ?? 'ذكر';
      final profileImage = _userProfile!['profile_image'];
      final isWhatsApp = authMethod == 'whatsapp';

      return InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
          _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              UserProfileAvatar(
                imagePath: profileImage,
                gender: gender,
                radius: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'أهلاً بك، $name',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isWhatsApp ? 'موثق عبر الواتساب' : 'موثق عبر البريد الإلكتروني',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        _loadData();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.person_add_alt_1_outlined, color: Color(0xFFD97706), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'لم تسجل الدخول بعد - اضغط هنا لتأكيد حسابك وحفظ بياناتك',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            Icon(Icons.arrow_back_ios_new, size: 14, color: Color(0xFFD97706)),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedCompletionCard({
    required int remainingPrayerDays,
    required int remainingFastingDays,
  }) {
    final now = DateTime.now();
    final maxRemainingDays = remainingPrayerDays > remainingFastingDays
        ? remainingPrayerDays
        : remainingFastingDays;

    if (maxRemainingDays <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ما شاء الله! لقد أتممت جميع الفروض والعبادات المطلوبة.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final datePace1 = now.add(Duration(days: maxRemainingDays));
    final datePace2 = now.add(Duration(days: (maxRemainingDays / 2).ceil()));

    String formatDate(DateTime dt) {
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'التاريخ المتوقع لإكمال القضاء',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildPaceInfo(
                  title: 'بمعدل يوم يومياً',
                  dateStr: formatDate(datePace1),
                  subtitle: '$maxRemainingDays يوم متبقٍ',
                ),
              ),
              Container(
                height: 28,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildPaceInfo(
                  title: 'بمعدل يومين يومياً',
                  dateStr: formatDate(datePace2),
                  subtitle: '${(maxRemainingDays / 2).ceil()} يوم متبقٍ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaceInfo({
    required String title,
    required String dateStr,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.amberAccent.shade100,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDedicationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.volunteer_activism, color: Color(0xFF0F766E), size: 26),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تطبيق لمتابعة قضاء ما في ذمتك من صلوات وصيام. أجر وثواب نشر واستخدام هذا العمل صدقة جارية لروح والدي وروح المرحومة زوجتي تحرير جابر (أم علي) رحمهما الله.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSection({
    required int totalPrayersRequired,
    required int completedCount,
    required int targetCount,
    required double progress,
    required int fajr,
    required int dhuhr,
    required int asr,
    required int maghrib,
    required int isha,
  }) {
    final fullCompletedDays = [fajr, dhuhr, asr, maghrib, isha]
        .reduce((a, b) => a < b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قضاء الصلوات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '$completedCount من $targetCount فريضة',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF0F766E),
                      ),
                      tooltip: 'تعديل مدة الصلاة المطلوبة بالأيام',
                      onPressed: () => _showEditTotalDialog(
                        'PRAYER',
                        'الصلوات',
                        totalPrayersRequired,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الأيام المقضية: $fullCompletedDays يوم من $totalPrayersRequired يوم',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildPrayerRowItem(
                  'صلاة الفجر',
                  fajr,
                  'completed_fajr',
                  'FAJR',
                ),
                _buildPrayerRowItem(
                  'صلاة الظهر',
                  dhuhr,
                  'completed_dhuhr',
                  'DHUHR',
                ),
                _buildPrayerRowItem('صلاة العصر', asr, 'completed_asr', 'ASR'),
                _buildPrayerRowItem(
                  'صلاة المغرب',
                  maghrib,
                  'completed_maghrib',
                  'MAGHRIB',
                ),
                _buildPrayerRowItem(
                  'صلاة العشاء',
                  isha,
                  'completed_isha',
                  'ISHA',
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DatabaseHelper.instance.logFullDayPrayer();
                  _triggerFeedback();
                  _showSuccessSnackbar('تم تسجيل قضاء صلوات يوم كامل');
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'تسجيل قضاء يوم كامل (5 صلوات)',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRowItem(
    String name,
    int count,
    String column,
    String actionName,
  ) {
    final int todayCount = _todayActionCounts[actionName] ?? 0;
    final bool isDoneToday = todayCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDoneToday
              ? const Color(0xFF0F766E).withValues(alpha: 0.10)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDoneToday
                ? const Color(0xFF0F766E).withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: isDoneToday ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: isDoneToday
                  ? const Color(0xFF0F766E)
                  : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDoneToday
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDoneToday
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDoneToday
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (isDoneToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        todayCount > 1
                            ? 'تم القضاء اليوم ($todayCount مرّات)'
                            : 'تم القضاء اليوم',
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  tooltip: 'خفض واحدة (تصحيح الخطأ)',
                  onPressed: () async {
                    if (count > 0) {
                      await DatabaseHelper.instance.decrementPrayer(
                        column,
                        actionName,
                      );
                      _triggerFeedback();
                      _showSuccessSnackbar('تم التراجع عن $name');
                      _loadData();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF0F766E),
                    size: 26,
                  ),
                  tooltip: 'قضاء فريضة',
                  onPressed: () async {
                    await DatabaseHelper.instance.logPrayer(column, actionName);
                    _triggerFeedback();
                    final newCount = todayCount + 1;
                    _showSuccessSnackbar(
                      'تقبل الله.. تم تسجيل $name (المرة $newCount اليوم)',
                    );
                    _loadData();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastingCard({
    required int totalRequired,
    required int completed,
    required double progress,
  }) {
    final remaining = (totalRequired - completed).clamp(0, totalRequired);
    final int todayFastingCount = _todayActionCounts['FASTING_DAY'] ?? 0;
    final bool isFastingDoneToday = todayFastingCount > 0;

    final completedMonths = completed ~/ 30;
    final currentCycleDays = completed % 30;
    final double cycleProgress = (currentCycleDays / 30.0).clamp(0.0, 1.0);

    String getCompletedMonthText(int count) {
      final names = [
        'الشهر الأول',
        'الشهر الثاني',
        'الشهر الثالث',
        'الشهر الرابع',
        'الشهر الخامس',
        'الشهر السادس',
        'الشهر السابع',
        'الشهر الثامن',
        'الشهر التاسع',
        'الشهر العاشر',
        'الشهر الحادي عشر',
        'الشهر الثاني عشر',
      ];
      if (count >= 1 && count <= names.length) {
        return names[count - 1];
      }
      return '$count أشهر';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
      ),
      elevation: 2,
      color: const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const Text(
                        'قضاء الصيام',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      if (isFastingDoneToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            todayFastingCount > 1
                                ? 'تم صيام اليوم ($todayFastingCount)'
                                : 'تم صيام اليوم',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed من $totalRequired يوم',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                      tooltip: 'تعديل أيام الصيام المطلوبة',
                      onPressed: () => _showEditTotalDialog(
                        'FASTING',
                        'الصيام',
                        totalRequired,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: cycleProgress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الدورة الحالية: $currentCycleDays من 30 يوم',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                Text(
                  '${(cycleProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            if (completedMonths >= 1) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم إكمال صيام ${getCompletedMonthText(completedMonths)} بنجاح 🎉',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المتبقي: $remaining يوم',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      tooltip: 'تراجع عن يوم صيام',
                      onPressed: () async {
                        if (completed > 0) {
                          await DatabaseHelper.instance.decrementFastingDay();
                          _triggerFeedback();
                          _showSuccessSnackbar('تم التراجع عن قضاء يوم صيام');
                          _loadData();
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await DatabaseHelper.instance.logFastingDay();
                        _triggerFeedback();
                        _showSuccessSnackbar('تقبل الله صيامكم اليوم');
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                      ),
                      label: Text(
                        isFastingDoneToday ? 'قضيتُ يوماً آخر' : 'قضيتُ يوماً',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
