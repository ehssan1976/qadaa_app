import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isPrayerByDuration = true;
  bool _isFastingByDuration = false;

  final _prayerYearsController = TextEditingController(text: '0');
  final _prayerMonthsController = TextEditingController(text: '0');
  final _prayerDaysController = TextEditingController(text: '0');

  final _fastingDaysController = TextEditingController(text: '0');
  final _fastingYearsController = TextEditingController(text: '0');
  final _fastingMonthsController = TextEditingController(text: '0');

  int _calculateDays({
    required bool byDuration,
    required String years,
    required String months,
    required String days,
  }) {
    if (byDuration) {
      final y = int.tryParse(years) ?? 0;
      final m = int.tryParse(months) ?? 0;
      return (y * 365) + (m * 30);
    } else {
      return int.tryParse(days) ?? 0;
    }
  }

  Future<void> _saveAndProceed() async {
    final totalPrayerDays = _calculateDays(
      byDuration: _isPrayerByDuration,
      years: _prayerYearsController.text,
      months: _prayerMonthsController.text,
      days: _prayerDaysController.text,
    );

    final totalFastingDays = _calculateDays(
      byDuration: _isFastingByDuration,
      years: _fastingYearsController.text,
      months: _fastingMonthsController.text,
      days: _fastingDaysController.text,
    );

    await DatabaseHelper.instance.setTotalDays('PRAYER', totalPrayerDays);
    await DatabaseHelper.instance.setTotalDays('FASTING', totalFastingDays);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
    );
  }

  @override
  void dispose() {
    _prayerYearsController.dispose();
    _prayerMonthsController.dispose();
    _prayerDaysController.dispose();
    _fastingDaysController.dispose();
    _fastingYearsController.dispose();
    _fastingMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final computedPrayerDays = _calculateDays(
      byDuration: _isPrayerByDuration,
      years: _prayerYearsController.text,
      months: _prayerMonthsController.text,
      days: _prayerDaysController.text,
    );

    final computedFastingDays = _calculateDays(
      byDuration: _isFastingByDuration,
      years: _fastingYearsController.text,
      months: _fastingMonthsController.text,
      days: _fastingDaysController.text,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'تحديد الفروض المطلوبة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0F766E), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أدخل تقديراً للأيام أو السنوات المطلوبة لقضاء ما في الذمة، ويمكنك تعديلها لاحقاً في أي وقت.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'قضاء الصلوات',
              icon: Icons.mosque_outlined,
              color: const Color(0xFF0F766E),
              isByDuration: _isPrayerByDuration,
              onToggleMode: (val) => setState(() => _isPrayerByDuration = val),
              totalResultDays: computedPrayerDays,
              yearsController: _prayerYearsController,
              monthsController: _prayerMonthsController,
              daysController: _prayerDaysController,
              unitLabel: 'فريضة من كل صلاة',
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'قضاء الصيام',
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFFD97706),
              isByDuration: _isFastingByDuration,
              onToggleMode: (val) => setState(() => _isFastingByDuration = val),
              totalResultDays: computedFastingDays,
              yearsController: _fastingYearsController,
              monthsController: _fastingMonthsController,
              daysController: _fastingDaysController,
              unitLabel: 'يوم صيام',
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saveAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: const Text(
                'حفظ وبدء المتابعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isByDuration,
    required ValueChanged<bool> onToggleMode,
    required int totalResultDays,
    required TextEditingController yearsController,
    required TextEditingController monthsController,
    required TextEditingController daysController,
    required String unitLabel,
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
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('بالسنوات والأشهر'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('بالأيام مباشرة'),
                ),
              ],
              selected: {isByDuration},
              onSelectionChanged: (Set<bool> newSelection) {
                onToggleMode(newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            if (isByDuration) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: yearsController,
                      label: 'عدد السنوات',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      controller: monthsController,
                      label: 'عدد الأشهر',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildNumberField(
                controller: daysController,
                label: 'إجمالي عدد الأيام',
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المجموع المحسوب:',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '$totalResultDays $unitLabel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}
