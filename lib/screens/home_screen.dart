import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'devotions_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _prayerData;
  Map<String, dynamic>? _fastingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prayers = await DatabaseHelper.instance.getObligation('PRAYER');
    final fasting = await DatabaseHelper.instance.getObligation('FASTING');
    setState(() {
      _prayerData = prayers;
      _fastingData = fasting;
      _isLoading = false;
    });
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
            borderRadius: BorderRadius.circular(14),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'عدد الأيام الإجمالي',
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
              ),
              onPressed: () async {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val >= 0) {
                  await DatabaseHelper.instance.updateTotalRequired(type, val);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    _showSuccessSnackbar('تم تحديث المدة بنجاح');
                  }
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
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

    final totalFastingRequired = _fastingData?['total_required'] ?? 0;
    final completedFasting = _fastingData?['completed_fasting'] ?? 0;
    final fastingProgress = totalFastingRequired > 0
        ? (completedFasting / totalFastingRequired).clamp(0.0, 1.0)
        : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
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
              icon: const Icon(Icons.edit_calendar_outlined),
              tooltip: 'تعديل خطة القضاء الإجمالية',
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const OnboardingScreen(isEditing: true),
                  ),
                );
                if (res == true) _loadData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.touch_app_outlined),
              tooltip: 'المسبحة والأذكار',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DevotionsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.backup_outlined),
              tooltip: 'النسخ الاحتياطي',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BackupScreen()),
                ).then((_) => _loadData());
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'عن التطبيق',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildDedicationCard(),
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
              'تطبيق لمتابعة قضاء ما في ذمتك من صلوات وصيام. أجر وثواب نشر واستخدام هذا العمل صدقة جارية لروح المرحومة تحرير جابر (أم علي) رحمها الله.',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$name: $count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
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
                size: 24,
              ),
              tooltip: 'قضاء فريضة',
              onPressed: () async {
                await DatabaseHelper.instance.logPrayer(column, actionName);
                _triggerFeedback();
                _showSuccessSnackbar('تم تسجيل $name');
                _loadData();
              },
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
                  'قضاء الصيام',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
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
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFFD97706),
              ),
            ),
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
                        _showSuccessSnackbar('تقبل الله صيامكم');
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('قضيتُ يوماً'),
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
