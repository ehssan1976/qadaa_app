import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _prayerYearsController = TextEditingController(text: '1');
  final _fastingDaysController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCurrentValues();
    }
  }

  Future<void> _loadCurrentValues() async {
    final prayer = await DatabaseHelper.instance.getObligation('PRAYER');
    final fasting = await DatabaseHelper.instance.getObligation('FASTING');
    if (prayer != null) {
      final totalDays = prayer['total_required'] ?? 365;
      final years = (totalDays / 365).round();
      _prayerYearsController.text = years > 0 ? years.toString() : '1';
    }
    if (fasting != null) {
      final days = fasting['total_required'] ?? 30;
      _fastingDaysController.text = days.toString();
    }
  }

  Future<void> _savePlan() async {
    final prayerYears = int.tryParse(_prayerYearsController.text.trim()) ?? 1;
    final fastingDays = int.tryParse(_fastingDaysController.text.trim()) ?? 30;

    final totalPrayerDays = prayerYears * 365;

    await DatabaseHelper.instance.setTotalDays('PRAYER', totalPrayerDays);
    await DatabaseHelper.instance.setTotalDays('FASTING', fastingDays);

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'تعديل خطة القضاء' : 'تحديد مدة القضاء',
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              const Text(
                'حدد خطة الفروض المطلوبة في ذمتك:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _prayerYearsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'قضاء الصلوات (عدد السنوات المطلوبة)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _fastingDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'قضاء الصيام (عدد الأيام المطلوبة)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _savePlan,
                child: Text(
                  widget.isEditing
                      ? 'تحديث الخطة والعودة'
                      : 'بدء متابعة القضاء',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
