import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text(
            'عن التطبيق والإهداء',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 46,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'تطبيق قضاء الفروض والعبادات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Center(
              child: Text(
                'صدقة جارية',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: Color(0xFF0F766E),
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'إهداء وثواب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'أُعِدَّ هذا التطبيق بنية خالصة ليكون صدقة جارية ونوراً لزوجتي العزيزة رحمها الله وأسكنها فسيح جناته.\n\n'
                      'نسأل كل من انتفع بهذا التطبيق في قضاء فروضه أو ذِكْر ربه أن يشملها بخالص دعائه بالرحمة والمغفرة وأن يجمعنا بها في مستقر رحمته.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.8,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '«اللهم اغفر لها وارحمها، واجعل قبرها روضة من رياض الجنة»',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مميزات التطبيق',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.block_outlined,
                      'مجاني بالكامل وخالٍ تماماً من الإعلانات.',
                    ),
                    _buildFeatureItem(
                      Icons.wifi_off_outlined,
                      'يعمل دون الحاجة إلى اتصال بالإنترنت.',
                    ),
                    _buildFeatureItem(
                      Icons.lock_outline,
                      'بياناتك محفوظة محلياً على جهازك دون مشاركتها.',
                    ),
                    _buildFeatureItem(
                      Icons.save_outlined,
                      'إمكانية حفظ واسترجاع النسخ الاحتياطية يدوياً.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'الإصدار 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
