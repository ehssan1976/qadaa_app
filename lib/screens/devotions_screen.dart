import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DevotionsScreen extends StatefulWidget {
  const DevotionsScreen({super.key});

  @override
  State<DevotionsScreen> createState() => _DevotionsScreenState();
}

class _DevotionsScreenState extends State<DevotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _counter = 0;
  int _target = 33;
  int _totalCompletedCycles = 0;
  String _selectedDhikr = 'سبحان الله وبحمده، سبحان الله العظيم';

  final List<String> _presetAdhkar = [
    'سبحان الله وبحمده، سبحان الله العظيم',
    'استغفر الله ربي وأتوب إليه',
    'اللهم صلِّ على محمد وآل محمد',
    'لا إله إلا الله وحده لا شريك له',
    'لا حول ولا قوة إلا بالله العلي العظيم',
    'سورة الفاتحة (قراءة وإهداء الثواب)',
  ];

  final List<Map<String, String>> _deceasedDuas = [
    {
      'title': 'دعاء المغفرة والرحمة',
      'body':
          'اللهم اغفر لها وارحمها، وعافها واعف عنها، وأكرم نزلها، ووسّع مدخلها، واغسلها بالماء والثلج والبرد، ونقّها من الذنوب والخطايا كما ينقّى الثوب الأبيض من الدنس.',
    },
    {
      'title': 'دعاء النور والفسحة في القبر',
      'body':
          'اللهم آنس وحشتها، وارحم غربتها، واجعل قبرها روضة من رياض الجنة ولا تجعله حفرة من حفر النار، وافسح لها في قبرها مدّ بصرها.',
    },
    {
      'title': 'دعاء الدرجات العُلا',
      'body':
          'اللهم إن كانت محسنة فزد في إحسانها، وإن كانت مسيئة فتجاوز عن سيئاتها، وأسكنها الفردوس الأعلى مع النبيين والصديقين والشهداء والصالحين.',
    },
    {
      'title': 'إهداء ثواب العمل والصدقة',
      'body':
          'اللهم إني أحتسب أجر هذا العمل وهذا الذكر صدقة جارية لها، فاللهم اجعل ثوابه نوراً ينزل على قبرها، وتقبله بقبولك الحسن يا أرحم الراحمين.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _incrementTasbeeh() {
    setState(() {
      _counter++;
      if (_counter >= _target) {
        _counter = 0;
        _totalCompletedCycles++;
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text(
            'الأعمال العبادية والأذكار',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0F766E),
            labelColor: const Color(0xFF0F766E),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.touch_app_outlined),
                text: 'المسبحة الإلكترونية',
              ),
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'أدعية للمتوفى'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildTasbeehTab(), _buildDuasTab()],
        ),
      ),
    );
  }

  Widget _buildTasbeehTab() {
    final progress = (_counter / _target).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 4.0,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedDhikr,
                items: _presetAdhkar.map((dhikr) {
                  return DropdownMenuItem(
                    value: dhikr,
                    child: Text(
                      dhikr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDhikr = val;
                      _counter = 0;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('الدورة: ', style: TextStyle(color: Colors.grey)),
            ChoiceChip(
              label: const Text('33'),
              selected: _target == 33,
              onSelected: (val) => setState(() {
                _target = 33;
                _counter = 0;
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('100'),
              selected: _target == 100,
              onSelected: (val) => setState(() {
                _target = 100;
                _counter = 0;
              }),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _incrementTasbeeh,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_counter',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      Text(
                        'من $_target',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'المس للتسبيح',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'الدورات المكتملة',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '$_totalCompletedCycles',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _resetCounter,
              icon: const Icon(Icons.refresh, color: Colors.grey),
              tooltip: 'إعادة تعيين العداد',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDuasTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _deceasedDuas.length,
      itemBuilder: (context, index) {
        final item = _deceasedDuas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_outline,
                      size: 18,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['body']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
