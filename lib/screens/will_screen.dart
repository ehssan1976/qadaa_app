import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../utils/print_and_share_helper.dart';

class WillScreen extends StatefulWidget {
  const WillScreen({super.key});

  @override
  State<WillScreen> createState() => _WillScreenState();
}

class _WillScreenState extends State<WillScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _willAssets = [];

  final _testatorController = TextEditingController();
  final _executorsController = TextEditingController();
  final _thirdAllocationController = TextEditingController();
  final _wishesController = TextEditingController();
  final _witness1Controller = TextEditingController();
  final _witness2Controller = TextEditingController();

  final Map<String, Map<String, dynamic>> _categories = {
    'CASH': {
      'label': 'أموال ونقود ومصارف',
      'icon': Icons.attach_money_rounded,
      'color': const Color(0xFF10B981),
    },
    'GOLD': {
      'label': 'ذهب ومجوهرات وسبائك',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFFF59E0B),
    },
    'REAL_ESTATE': {
      'label': 'بيوت وعقارات ومحلات',
      'icon': Icons.home_work_rounded,
      'color': const Color(0xFF0F766E),
    },
    'LAND': {
      'label': 'أراضي ومزارع',
      'icon': Icons.landscape_rounded,
      'color': const Color(0xFF84CC16),
    },
    'VEHICLE': {
      'label': 'سيارات ومراكب',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF3B82F6),
    },
    'OTHER': {
      'label': 'ممتلكات وحقوق أخرى',
      'icon': Icons.widgets_rounded,
      'color': const Color(0xFF8B5CF6),
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWillData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _testatorController.dispose();
    _executorsController.dispose();
    _thirdAllocationController.dispose();
    _wishesController.dispose();
    _witness1Controller.dispose();
    _witness2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadWillData() async {
    setState(() => _isLoading = true);
    try {
      final info = await DatabaseHelper.instance.getWillInfo();
      final assets = await DatabaseHelper.instance.getWillAssets();
      if (mounted) {
        setState(() {
          _willAssets = assets;
          _testatorController.text = info?['testator_name'] ?? '';
          _executorsController.text = info?['executors'] ?? '';
          _thirdAllocationController.text = info?['third_allocation'] ?? '';
          _wishesController.text = info?['general_wishes'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading will data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWillInfo() async {
    final data = {
      'testator_name': _testatorController.text.trim(),
      'executors': _executorsController.text.trim(),
      'third_allocation': _thirdAllocationController.text.trim(),
      'general_wishes': _wishesController.text.trim(),
    };
    await DatabaseHelper.instance.saveWillInfo(data);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بنود الوصية الشرعية بنجاح'),
          backgroundColor: Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAssetDialog({Map<String, dynamic>? assetToEdit}) async {
    final isEditing = assetToEdit != null;
    String category = assetToEdit?['category'] ?? 'REAL_ESTATE';
    final titleController = TextEditingController(text: assetToEdit?['title'] ?? '');
    final descriptionController = TextEditingController(text: assetToEdit?['description'] ?? '');
    final valueController = TextEditingController(text: assetToEdit?['estimated_value'] ?? '');
    final locationController = TextEditingController(text: assetToEdit?['location_or_details'] ?? '');
    final beneficiaryController = TextEditingController(text: assetToEdit?['beneficiary_notes'] ?? '');

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'تعديل ممتلك / عقار في التركة' : 'إضافة ممتلك أو عقار جديد للتركة',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Category Selector Dropdown
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'نوع الممتلك / العقار *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        items: _categories.entries.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(e.value['icon'] as IconData, color: e.value['color'] as Color, size: 20),
                                const SizedBox(width: 8),
                                Text(e.value['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Title
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'اسم/عنوان الممتلك *',
                          hintText: 'مثال: البيت السكني في بغداد / سيارة تويوتا / قطعة أرض مزارع',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة عنوان الممتلك' : null,
                      ),
                      const SizedBox(height: 14),

                      // Description / Quantity
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'الوصف أو الكمية / المساحة',
                          hintText: 'مثال: مساحة 200م² / وزن 100 غرام ذهب / 50 ألف دولار',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Estimated Value
                      TextFormField(
                        controller: valueController,
                        decoration: const InputDecoration(
                          labelText: 'القيمة التقديرية (اختياري)',
                          hintText: 'مثال: 150,000,000 د.ع',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Location / Document / Details
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'الموقع أو مكان حفظ السند / المفاتيح',
                          hintText: 'مثال: السند في التجوري الخزنة / مفاتيح القاصة عند أم أحمد',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Beneficiary Notes / Partition Wishes
                      TextFormField(
                        controller: beneficiaryController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'توصيات أو توجيهات تقسيم خاصة بهذا الممتلك',
                          hintText: 'مثال: تباع وتقسم حسَب الشرع / يترك للزوجة / يخصص ثمنه لقضاء الصلاة والصوم',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final data = {
                                'category': category,
                                'title': titleController.text.trim(),
                                'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                                'estimated_value': valueController.text.trim().isEmpty ? null : valueController.text.trim(),
                                'location_or_details': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                                'beneficiary_notes': beneficiaryController.text.trim().isEmpty ? null : beneficiaryController.text.trim(),
                                'date_added': DateTime.now().toIso8601String().split('T').first,
                              };

                              if (isEditing) {
                                await DatabaseHelper.instance.updateWillAsset(assetToEdit['id'], data);
                              } else {
                                await DatabaseHelper.instance.insertWillAsset(data);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadWillData();
                              HapticFeedback.mediumImpact();
                            }
                          },
                          icon: Icon(isEditing ? Icons.save : Icons.add_circle, color: Colors.white),
                          label: Text(
                            isEditing ? 'حفظ التعديلات' : 'إضافة الممتلك إلى التركة',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showWillDocumentDialog() async {
    final debts = await DatabaseHelper.instance.getDebts();
    if (!mounted) return;
    final activeOwed = debts.where((d) => d['type'] == 'OWED' && (d['is_settled'] ?? 0) == 0).toList();
    final activeLent = debts.where((d) => d['type'] == 'LENT' && (d['is_settled'] ?? 0) == 0).toList();

    final name = _testatorController.text.trim().isNotEmpty ? _testatorController.text.trim() : 'الموصي';
    final executors = _executorsController.text.trim();
    final thirdAllocation = _thirdAllocationController.text.trim();
    final wishes = _wishesController.text.trim();

    final buffer = StringBuffer();
    buffer.writeln('📜 *وثيقة الوصية الشرعية وتثبيت التركة والحقوق*');
    buffer.writeln('تاريخ التحرير: ${DateTime.now().toIso8601String().split('T').first}');
    buffer.writeln('==========================================');
    buffer.writeln('بسم الله الرحمن الرحيم');
    buffer.writeln('«كُتِبَ عَلَيْكُمْ إِذَا حَضَرَ أَحَدَكُمُ الْمَوْتُ إِن تَرَكَ خَيْرًا الْوَصِيَّةُ لِلْوَالِدَيْنِ وَالأَقْرَبِينَ بِالْمَعْرُوفِ حَقًّا عَلَى الْمُتَّقِينَ»');
    buffer.writeln();
    buffer.writeln('أنا العبد الفقير إلى الله تعالى ($name)، وأنا في أتم الصحة والعقل ونفاذ الإرادة، أقر وأوصي بما يلي:');
    buffer.writeln();

    if (executors.isNotEmpty) {
      buffer.writeln('👤 *الوصي والأوصياء على تنفيذ الوصية:*');
      buffer.writeln(executors);
      buffer.writeln();
    }

    buffer.writeln('🏛️ *أولاً: حصر الممتلكات والتركة:*');
    if (_willAssets.isEmpty) {
      buffer.writeln('• لم يتم تثبيت ممتلكات في التركة بعد.');
    } else {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final asset in _willAssets) {
        final cat = asset['category'] as String? ?? 'OTHER';
        grouped.putIfAbsent(cat, () => []).add(asset);
      }

      grouped.forEach((catKey, items) {
        final catLabel = _categories[catKey]?['label'] ?? 'ممتلكات أخرى';
        buffer.writeln('🔹 *[$catLabel]:*');
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          buffer.write('  ${i + 1}. ${item['title']}');
          if (item['description'] != null && item['description'].toString().isNotEmpty) {
            buffer.write(' (${item['description']})');
          }
          if (item['estimated_value'] != null && item['estimated_value'].toString().isNotEmpty) {
            buffer.write(' - القيمة: ${item['estimated_value']}');
          }
          buffer.writeln();
          if (item['location_or_details'] != null && item['location_or_details'].toString().isNotEmpty) {
            buffer.writeln('     مكان الحفظ/السند: ${item['location_or_details']}');
          }
          if (item['beneficiary_notes'] != null && item['beneficiary_notes'].toString().isNotEmpty) {
            buffer.writeln('     التوجيه الخاص: ${item['beneficiary_notes']}');
          }
        }
        buffer.writeln();
      });
    }

    buffer.writeln('⚖️ *ثانياً: الحقوق والديون المالية:*');
    if (activeOwed.isNotEmpty) {
      buffer.writeln('• ديون عليّ للغير (تخرج أولاً من التركة قبل التقسيم):');
      for (final d in activeOwed) {
        buffer.writeln('  - ${d['person_name']}: ${d['amount']} ${d['currency']} (${d['date']})');
      }
    } else {
      buffer.writeln('• لا توجد ديون نشطة عليّ بحمد الله.');
    }

    if (activeLent.isNotEmpty) {
      buffer.writeln('• ديون لي على الغير (تستحصل لتضاف للتركة):');
      for (final d in activeLent) {
        buffer.writeln('  - ${d['person_name']}: ${d['amount']} ${d['currency']} (${d['date']})');
      }
    }
    buffer.writeln();

    if (thirdAllocation.isNotEmpty) {
      buffer.writeln('🕌 *ثالثاً: الوصية بالثلث الشرعي:*');
      buffer.writeln(thirdAllocation);
      buffer.writeln();
    }

    if (wishes.isNotEmpty) {
      buffer.writeln('🤍 *رابعاً: التوصيات والوصايا العامة للورثة والأهل:*');
      buffer.writeln(wishes);
      buffer.writeln();
    }

    buffer.writeln('==========================================');
    buffer.writeln('نسأل الله أن يبارك في العمر، وأن يجعل آخر كلامنا لا إله إلا الله محمد رسول الله علي ولي الله.');
    buffer.writeln();
    buffer.writeln('✍️ *التوقيع والمصادقة الشرعية:*');
    buffer.writeln('• اسم الموصي: $name');
    buffer.writeln('• توقيع الموصي: ............................................');
    buffer.writeln('• تاريخ التوقيع: ${DateTime.now().toIso8601String().split('T').first}');
    buffer.writeln();
    buffer.writeln('👥 *إشهاد الشهود العدول (شهود عدد 2):*');
    final w1 = _witness1Controller.text.trim();
    final w2 = _witness2Controller.text.trim();
    buffer.writeln('1️⃣ الشاهد الأول: ${w1.isNotEmpty ? w1 : '........................................'}');
    buffer.writeln('   - التوقيع: ............................................');
    buffer.writeln();
    buffer.writeln('2️⃣ الشاهد الثاني: ${w2.isNotEmpty ? w2 : '........................................'}');
    buffer.writeln('   - التوقيع: ............................................');

    final docText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.history_edu, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text('سند الوصية الشرعية وثبت التركة 📜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: SelectableText(
                  docText,
                  style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF1E293B)),
                ),
              ),
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => PrintAndShareHelper.copyToClipboard(
                    context,
                    docText,
                    'تم نسخ سند الوصية إلى الحافظة بنجاح',
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('نسخ السند'),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.printDocument(
                    title: 'سند الوصية الشرعية وثبت التركة',
                    content: docText,
                  ),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('طباعة السند'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.shareToWhatsApp(docText),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('واتساب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.shareDocument(
                    context: context,
                    title: 'وثيقة الوصية الشرعية وحصر التركة',
                    content: docText,
                  ),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('مشاركة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
          title: const Text(
            'الوصية الشرعية وحصر التركة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'إصدار سند الوصية',
              onPressed: _showWillDocumentDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0F766E),
            labelColor: const Color(0xFF0F766E),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: 'حصر الممتلكات والتركة',
              ),
              Tab(
                icon: Icon(Icons.gavel_outlined),
                text: 'الوصية الشرعية والتقسيم',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAssetDialog(),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_home_outlined),
          label: const Text('إضافة ممتلك / عقار', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildAssetsTab(),
                  _buildWillFormTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAssetsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF042F2E)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.3),
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
                        'إجمالي الممتلكات المسجلة',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_willAssets.length} ممتلكات وعقارات',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _showWillDocumentDialog,
                    icon: const Icon(Icons.assignment_outlined, color: Colors.amberAccent, size: 16),
                    label: const Text('معاينة الوصية 📜', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amberAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'تثبيت الأموال والذهب والعقارات والسيارات لضمان حفظ حقوقك وحقوق الورثة شرعاً',
                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.inventory, color: Color(0xFF0F766E), size: 20),
            SizedBox(width: 8),
            Text(
              'قائمة ممتلكات التركة حسب التصنيف:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_willAssets.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.home_work_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'لم تقم بإضافة ممتلكات أو عقارات للتركة بعد',
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اضغط على "+ إضافة ممتلك / عقار" لتثبيت ممتلكاتك',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ..._willAssets.map((asset) {
            final catKey = asset['category'] as String? ?? 'OTHER';
            final catInfo = _categories[catKey] ?? _categories['OTHER']!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (catInfo['color'] as Color).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(catInfo['icon'] as IconData, color: catInfo['color'] as Color, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              asset['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        if (asset['estimated_value'] != null && asset['estimated_value'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              asset['estimated_value'].toString(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (asset['description'] != null && asset['description'].toString().isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'الوصف/الكمية: ${asset['description']}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    if (asset['location_or_details'] != null && asset['location_or_details'].toString().isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'الموقع/السند: ${asset['location_or_details']}',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    if (asset['beneficiary_notes'] != null && asset['beneficiary_notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.assignment_ind_outlined, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'توصية التقسيم: ${asset['beneficiary_notes']}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: const Color(0xFF0F766E),
                          tooltip: 'تعديل',
                          onPressed: () => _showAssetDialog(assetToEdit: asset),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.redAccent,
                          tooltip: 'حذف',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  title: const Text('حذف ممتلك من التركة'),
                                  content: Text('هل أنت تأكد من حذف (${asset['title']}) من قائمة التركة؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('إلغاء'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (confirm == true) {
                              await DatabaseHelper.instance.deleteWillAsset(asset['id']);
                              _loadWillData();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWillFormTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu, color: Color(0xFF0F766E)),
                    SizedBox(width: 8),
                    Text(
                      'بنود وتوصيات الوصية الشرعية',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Testator Name
                TextFormField(
                  controller: _testatorController,
                  decoration: const InputDecoration(
                    labelText: 'اسم صاحب الوصية (الموصي) *',
                    hintText: 'الاسم الثلاثي أو اللقب',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                // Executors
                TextFormField(
                  controller: _executorsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الوصي / الأوصياء على تنفيذ الوصية',
                    hintText: 'مثال: وصيّي في تنفيذ هذه الوصية هو ولدي الأكبر (أحمد) ورقم هاتفه (...) بمشورة الشيخ/الجهة...',
                    prefixIcon: Icon(Icons.gavel_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                // Third Allocation (الثلث الشرعي)
                TextFormField(
                  controller: _thirdAllocationController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الوصية بالثلث الشرعي (الخيرات والصلوات والدين)',
                    hintText: 'مثال: أخصص الثلث الشرعي لقضاء ما عليّ من صلاة وصيام، وإقامة مجالس العزاء، والصدقة الجارية...',
                    prefixIcon: Icon(Icons.volunteer_activism_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                // General Wishes / Division Guidelines
                TextFormField(
                  controller: _wishesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'توصيات عامة وتقسيم التركة للورثة والأبناء',
                    hintText: 'مثال: أوصي أبنائي بتقوى الله وصلة الرحم والتعاون، وأن تقسم التركة وفقاً للشرع الشريف وبمحبة وسماحة...',
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                // Witnesses (الشهود)
                TextFormField(
                  controller: _witness1Controller,
                  decoration: const InputDecoration(
                    labelText: 'اسم وتفاصيل الشاهد الأول (اختياري)',
                    hintText: 'مثال: الحاج أبو محمد - 07700000000',
                    prefixIcon: Icon(Icons.person_add_alt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _witness2Controller,
                  decoration: const InputDecoration(
                    labelText: 'اسم وتفاصيل الشاهد الثاني (اختياري)',
                    hintText: 'مثال: الأستاذ علي الحسين - 07800000000',
                    prefixIcon: Icon(Icons.person_add_alt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveWillInfo,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('حفظ بنود الوصية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
