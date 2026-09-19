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
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'سورة الفاتحة (قراءة وإهداء الثواب)',
  ];

  final List<Map<String, String>> _duasAndZiyarat = [
    {
      'title': 'دعاء كميل (مستحب قراءته ليلة الجمعة)',
      'body':
          '''اللَّهُمَّ إِنِّي أَسْأَلُكَ بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ، وَبِقُوَّتِكَ الَّتِي قَهَرْتَ بِهَا كُلَّ شَيْءٍ، وَخَضَعَ لَهَا كُلُّ شَيْءٍ، وَذَلَّ لَهَا كُلُّ شَيْءٍ، وَبِجَبَرُوتِكَ الَّتِي غَلَبْتَ بِهَا كُلَّ شَيْءٍ، وَبِعِزَّتِكَ الَّتِي لاَ يَقُومُ لَهَا شَيْءٌ، وَبِعَظَمَتِكَ الَّتِي مَلأَتْ كُلَّ شَيْءٍ، وَبِسُلْطَانِكَ الَّذِي عَلاَ كُلَّ شَيْءٍ، وَبِوَجْهِكَ الْبَاقِي بَعْدَ فَنَاءِ كُلِّ شَيْءٍ، وَبِأَسْمَائِكَ الَّتِي مَلأَتْ أَرْكَانَ كُلِّ شَيْءٍ، وَبِعِلْمِكَ الَّذِي أَحَاطَ بِكُلِّ شَيْءٍ، وَبِنُورِ وَجْهِكَ الَّذِي أَضَاءَ لَهُ كُلُّ شيء...

يَا نُورُ يَا قُدُّوسُ، يَا أَوَّلَ الأَوَّلِينَ، وَيَا آخِرَ الآخِرِينَ. اللَّهُمَّ اغْفِرْ لِيَ الذُّنُوبَ الَّتِي تَهْتِكُ الْعِصَمَ، اللَّهُمَّ اغْفِرْ لِيَ الذُّنُوبَ الَّتِي تُنْزِلُ النِّقَمَ، اللَّهُمَّ اغْفِرْ لِيَ الذُّنُوبَ الَّتِي تُغَيِّرُ النِّعَمَ، اللَّهُمَّ اغْفِرْ لِيَ الذُّنُوبَ الَّتِي تَحْبِسُ الدُّعَاءَ، اللَّهُمَّ اغْفِرْ لِيَ الذُّنُوبَ الَّتِي تُنْزِلُ الْبَلاَءَ...

فَهَبْنِي يَا إِلَهِي وَسَيِّدِي وَمَوْلاَيَ وَرَبِّي، صَبَرْتُ عَلَى عَذَابِكَ فَكَيْفَ أَصْبِرُ عَلَى فِرَاقِكَ، وَهَبْنِي صَبَرْتُ عَلَى حَرِّ نَارِكَ فَكَيْفَ أَصْبِرُ عَنِ النَّظَرِ إِلَى كَرَامَتِكَ، أَمْ كَيْفَ أَسْكُنُ فِي النَّارِ وَرَجَائِي عَفْوُكَ...

يَا رَبِّ يَا رَبِّ يَا رَبِّ، أَسْأَلُكَ بِحَقِّكَ وَقُدْسِكَ وَأَعْظَمِ صِفَاتِكَ وَأَسْمَائِكَ، أَنْ تَجْعَلَ أَوْقَاتِي مِنَ اللَّيْلِ وَالنَّهَارِ بِذِكْرِكَ مَعْمُورَةً، وَبِخِدْمَتِكَ مَوْصُولَةً، وَأَعْمَالِي عِنْدَكَ مَقْبُولَةً...

(يُستحب قراءته ليلة الجمعة وإهداء ثوابه لروح المرحومة تحرير جابر أم علي وأموات المؤمنين جميعاً).''',
    },
    {
      'title': 'دعاء للمرحومة تحرير جابر (أم علي)',
      'body':
          'اللهم اغفر لأمتك تحرير جابر، وارحمها وعافها واعفُ عنها، وأكرم نزلها ووسّع مدخلها، واغسلها بالماء والثلج والبرد، ونقّها من الذنوب والخطايا كما ينقّى الثوب الأبيض من الدنس، وجازها بالإحسان إحساناً وبالسيئات غفراناً.',
    },
    {
      'title': 'دعاء النور والفسحة في القبر',
      'body':
          'اللهم آنس وحشتها، وارحم غربتها، واجعل قبرها روضة من رياض الجنة ولا تجعله حفرة من حفر النار، وافسح لها في قبرها مدّ بصرها، وأنزل على قبرها الضياء والنور والفسحة والسرور.',
    },
    {
      'title': 'إهداء ثواب الطاعات والأذكار',
      'body':
          'اللهم إني أحتسب ثواب وأجر هذه الأذكار والدعوات صدقة جارية ونوراً واصلاً لروح المرحومة تحرير جابر (أم علي)، فتقبله بقبولك الحسن يا رب العالمين.',
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
                text: 'المسبحة والأذكار',
              ),
              Tab(
                icon: Icon(Icons.menu_book_outlined),
                text: 'الأدعية والزيارات',
              ),
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
        Center(
          child: GestureDetector(
            onTap: _incrementTasbeeh,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
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
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      Text(
                        'من $_target',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'المس للتسبيح',
                        style: TextStyle(
                          fontSize: 11,
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
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'الذكر الحالي: $_selectedDhikr',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'الدورة: ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                ChoiceChip(
                  label: const Text('33'),
                  selected: _target == 33,
                  onSelected: (val) => setState(() {
                    _target = 33;
                    _counter = 0;
                  }),
                ),
                const SizedBox(width: 6),
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
            Row(
              children: [
                Text(
                  'المكتمل: $_totalCompletedCycles',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  onPressed: _resetCounter,
                  icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                  tooltip: 'تصفير العداد',
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 24),
        const Text(
          'اختر تسبيحة أو ذكراً للبدء به:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        ..._presetAdhkar.map((dhikr) {
          final isSelected = dhikr == _selectedDhikr;
          return Card(
            elevation: isSelected ? 2 : 0.5,
            color: isSelected ? Colors.teal.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF0F766E)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF0F766E) : Colors.grey,
              ),
              title: Text(
                dhikr,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedDhikr = dhikr;
                  _counter = 0;
                });
                HapticFeedback.selectionClick();
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDuasTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _duasAndZiyarat.length,
      itemBuilder: (context, index) {
        final item = _duasAndZiyarat[index];
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
                      Icons.menu_book,
                      size: 18,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['body']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
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
