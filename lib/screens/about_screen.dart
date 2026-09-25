import 'package:flutter/material.dart';
import '../widgets/app_logo_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('عن التطبيق والإهداء'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Center(
              child: AppLogoIcon(size: 75),
            ),
            const SizedBox(height: 16),
            const Text(
              'تطبيق قضاء الفروض والعبادات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'إهداء وصدقة جارية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'نُهدي ثواب نشر واستخدام هذا التطبيق خالصاً لوجه الله تعالى إلى روح والدي وروح المرحومة زوجتي تحرير جابر (أم علي) رحمهما الله وأسكنهما فسيح جناته وجعل روضتهما من رياض الجنة. نسألكم الدعاء وقراءة الفاتحة لأرواحهما الطاهرة وأموات المؤمنين والمؤمنات جميعاً.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'الإصدار 1.0.2 - تم تصميمه للعمل دون اتصال بالإنترنت وحفظ البيانات محلياً على جهازك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
