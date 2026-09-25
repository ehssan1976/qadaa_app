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

  int _target = 33;
  double _duaFontSize = 14.0;
  final Map<String, int> _adhkarCounts = {};
  final Map<String, int> _adhkarCompletedCycles = {};

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

(يُستحب قراءته ليلة الجمعة وإهداء ثوابه لجميع أموات المؤمنين والمؤمنات).''',
    },
    {
      'title': 'دعاء للوالدين والأموات',
      'body':
          'اللهم اغفر لوالدينا ولجميع أموات المؤمنين والمؤمنات، وارحمهم وعافهم واعفُ عنهم، وأكرم نزلهم ووسّع مدخلهم، واغسلهم بالماء والثلج والبرد، ونقّهم من الذنوب والخطايا كما ينقّى الثوب الأبيض من الدنس، وجازهم بالإحسان إحساناً وبالسيئات غفراناً.',
    },
    {
      'title': 'دعاء النور والفسحة في القبر',
      'body':
          'اللهم آنس وحشتهم، وارحم غربتهم، واجعل قبورهم روضة من رياض الجنة ولا تجعلها حفرة من حفر النار، وافسح لهم في قبورهم مدّ بصرهم، وأنزل على قبورهم الضياء والنور والفسحة والسرور.',
    },
    {
      'title': 'إهداء ثواب الطاعات والأذكار',
      'body':
          'اللهم إني أحتسب ثواب وأجر هذه الأذكار والدعوات صدقة جارية ونوراً واصلاً لأرواح والدينا وأمواتنا وأموات المؤمنين والمؤمنات، فتقبله بقبولك الحسن يا رب العالمين.',
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

  void _incrementDhikr(String dhikr) {
    setState(() {
      final current = _adhkarCounts[dhikr] ?? 0;
      if (current + 1 >= _target) {
        _adhkarCounts[dhikr] = 0;
        _adhkarCompletedCycles[dhikr] = (_adhkarCompletedCycles[dhikr] ?? 0) + 1;
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 أتممت دورة ($dhikr) بنجاح!'),
            backgroundColor: const Color(0xFF0F766E),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _adhkarCounts[dhikr] = current + 1;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _decrementDhikr(String dhikr) {
    setState(() {
      final current = _adhkarCounts[dhikr] ?? 0;
      if (current > 0) {
        _adhkarCounts[dhikr] = current - 1;
      }
    });
  }

  void _resetDhikr(String dhikr) {
    setState(() {
      _adhkarCounts[dhikr] = 0;
      _adhkarCompletedCycles[dhikr] = 0;
    });
  }

  void _resetAllAdhkar() {
    setState(() {
      _adhkarCounts.clear();
      _adhkarCompletedCycles.clear();
    });
  }

  int get _totalTasbeehCount {
    int total = 0;
    for (final dhikr in _presetAdhkar) {
      total += (_adhkarCounts[dhikr] ?? 0) + ((_adhkarCompletedCycles[dhikr] ?? 0) * _target);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text(
            'المسبحة والأدعية',
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
                text: 'المسبحة',
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F766E),
                Color(0xFF0D9488),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي تسبيحات الجلسة',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_totalTasbeehCount',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetAllAdhkar,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('تصفير الكـل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الهدف لكل دورة:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('33 مرة'),
                        selected: _target == 33,
                        selectedColor: Colors.amberAccent,
                        backgroundColor: Colors.white24,
                        labelStyle: TextStyle(
                          color: _target == 33 ? const Color(0xFF0F766E) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setState(() {
                          _target = 33;
                        }),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('100 مرة'),
                        selected: _target == 100,
                        selectedColor: Colors.amberAccent,
                        backgroundColor: Colors.white24,
                        labelStyle: TextStyle(
                          color: _target == 100 ? const Color(0xFF0F766E) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setState(() {
                          _target = 100;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.touch_app_rounded, color: Color(0xFF0F766E), size: 20),
            SizedBox(width: 8),
            Text(
              'انقر على العبارة مباشرة للتسبيح:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._presetAdhkar.map((dhikr) {
          final count = _adhkarCounts[dhikr] ?? 0;
          final cycles = _adhkarCompletedCycles[dhikr] ?? 0;
          final progress = (count / _target).clamp(0.0, 1.0);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: count > 0 ? 2 : 0.5,
            color: count > 0 ? const Color(0xFFF0FDFA) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: count > 0 ? const Color(0xFF0F766E) : Colors.grey.shade200,
                width: count > 0 ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _incrementDhikr(dhikr),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            dhikr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: count > 0 ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (cycles > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 3),
                                Text(
                                  'دورة $cycles',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Progress bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Counter Badge (Vivid, Colored Second Counter Field)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: count > 0
                                  ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
                                  : const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (count > 0 ? const Color(0xFFD97706) : const Color(0xFF0F766E)).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                ' / $_target',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app, size: 14, color: Color(0xFF0F766E)),
                            SizedBox(width: 4),
                            Text(
                              'اضغط للعد المباشر',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (count > 0) ...[
                              IconButton(
                                onPressed: () => _decrementDhikr(dhikr),
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                color: Colors.grey.shade600,
                                tooltip: 'إنقاص 1',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              IconButton(
                                onPressed: () => _resetDhikr(dhikr),
                                icon: const Icon(Icons.refresh, size: 18),
                                color: Colors.grey.shade500,
                                tooltip: 'تصفير',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => _incrementDhikr(dhikr),
                                icon: const Icon(Icons.add, size: 20),
                                color: const Color(0xFF0F766E),
                                tooltip: 'تسبيح +1',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }


  Widget _buildDuasTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_size, size: 20, color: Color(0xFF0F766E)),
                  SizedBox(width: 6),
                  Text(
                    'حجم خط القراءة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    tooltip: 'تصغير الخط',
                    onPressed: _duaFontSize > 12.0
                        ? () => setState(() => _duaFontSize -= 1.0)
                        : null,
                  ),
                  Text(
                    '${_duaFontSize.toInt()} pt',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    tooltip: 'تكبير الخط',
                    onPressed: _duaFontSize < 24.0
                        ? () => setState(() => _duaFontSize += 1.0)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
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
                              style: TextStyle(
                                fontSize: _duaFontSize + 2.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['body']!,
                        style: TextStyle(
                          fontSize: _duaFontSize,
                          height: 1.8,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
