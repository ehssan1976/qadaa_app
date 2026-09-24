import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/print_and_share_helper.dart';

class KhumsScreen extends StatefulWidget {
  const KhumsScreen({super.key});

  @override
  State<KhumsScreen> createState() => _KhumsScreenState();
}

class _KhumsScreenState extends State<KhumsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _khumsInfo;
  List<Map<String, dynamic>> _khumsRecords = [];

  final _fiscalYearDateController = TextEditingController();
  final _fiscalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fiscalYearDateController.dispose();
    _fiscalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final info = await DatabaseHelper.instance.getKhumsInfo();
    final records = await DatabaseHelper.instance.getKhumsRecords();

    if (mounted) {
      setState(() {
        _khumsInfo = info;
        _khumsRecords = records;
        _fiscalYearDateController.text = info?['fiscal_year_date'] ?? '';
        _fiscalNotesController.text = info?['notes'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFiscalYearInfo() async {
    final dateStr = _fiscalYearDateController.text.trim();
    final notesStr = _fiscalNotesController.text.trim();

    if (dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال تاريخ رأس السنة الخمسية'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await DatabaseHelper.instance.saveKhumsInfo({
      'fiscal_year_date': dateStr,
      'notes': notesStr,
    });

    await _loadData();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ تاريخ رأس السنة الخمسية بنجاح 📅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditFiscalYearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.event, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text('تحديد رأس السنة الخمسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل تاريخ رأس السنة الخمسية الخاص بك (مثلاً: 15 شعبان / 1 رمضان أو تاريخ ميلادي محدد):',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _fiscalYearDateController,
                  decoration: InputDecoration(
                    labelText: 'تاريخ رأس السنة الخمسية',
                    hintText: 'مثال: 15 شعبان أو 01 يناير من كل عام',
                    prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _fiscalNotesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات وتوجيهات رأس السنة (اختياري)',
                    hintText: 'أي ملاحظات تخص رأس السنة الخمسية...',
                    prefixIcon: const Icon(Icons.notes, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: _saveFiscalYearInfo,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('حفظ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditRecordDialog([Map<String, dynamic>? record]) {
    final isEdit = record != null;

    final yearTitleCtrl = TextEditingController(text: record?['year_title'] ?? '');
    final dateCtrl = TextEditingController(text: record?['khums_date'] ?? DateTime.now().toIso8601String().split('T').first);
    final capitalCtrl = TextEditingController(text: record?['taxed_capital']?.toString() ?? '');
    final assetsCtrl = TextEditingController(text: record?['assets_detail'] ?? '');
    final paidCtrl = TextEditingController(text: record?['khums_paid']?.toString() ?? '0');
    final currencyCtrl = TextEditingController(text: record?['currency'] ?? 'د.ع');
    final notesCtrl = TextEditingController(text: record?['notes'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.add_card, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEdit ? 'تعديل بيانات السنة الخمسية' : 'إضافة سنة خمسية ورأس مال',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: yearTitleCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'السنة الخمسية *',
                      hintText: 'مثال: سنة 1446 هـ / 2025 م',
                      prefixIcon: const Icon(Icons.label, color: Color(0xFF0F766E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dateCtrl.text = picked.toIso8601String().split('T').first;
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'تاريخ المحاسبة *',
                      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0F766E)),
                      suffixIcon: const Icon(Icons.edit_calendar),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: capitalCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'رأس المال المخمّس *',
                            hintText: 'المبلغ المحسوب',
                            prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF0F766E)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: currencyCtrl,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'العملة',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: assetsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      isDense: true,
                      alignLabelWithHint: true,
                      labelText: 'الممتلكات والأصول المخمّسة',
                      hintText: 'تفاصيل الممتلكات (بضاعة، عقارات، ذهب...) وقيمتها',
                      prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF0F766E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'مقدار الخمس المدفوع (إن وجد)',
                      hintText: 'المبلغ المدفوع كخمس',
                      prefixIcon: const Icon(Icons.payments, color: Color(0xFF0F766E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      isDense: true,
                      alignLabelWithHint: true,
                      labelText: 'ملاحظات إضافية',
                      hintText: 'أي تفاصيل أخرى تخص حساب هذا العام...',
                      prefixIcon: const Icon(Icons.comment, color: Color(0xFF0F766E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final yearTitle = yearTitleCtrl.text.trim();
                final capitalStr = capitalCtrl.text.trim();

                if (yearTitle.isEmpty || capitalStr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى تعبئة اسم السنة ورأس المال المخمس'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final capitalVal = double.tryParse(capitalStr) ?? 0.0;
                final paidVal = double.tryParse(paidCtrl.text.trim()) ?? 0.0;

                final recData = {
                  'year_title': yearTitle,
                  'khums_date': dateCtrl.text.trim(),
                  'taxed_capital': capitalVal,
                  'assets_detail': assetsCtrl.text.trim(),
                  'currency': currencyCtrl.text.trim().isNotEmpty ? currencyCtrl.text.trim() : 'د.ع',
                  'khums_paid': paidVal,
                  'notes': notesCtrl.text.trim(),
                  'created_at': DateTime.now().toIso8601String(),
                };

                if (isEdit) {
                  await DatabaseHelper.instance.updateKhumsRecord(record['id'] as int, recData);
                } else {
                  await DatabaseHelper.instance.insertKhumsRecord(recData);
                }

                await _loadData();

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'تم تعديل بيانات السنة الخمسية بنجاح' : 'تم إضافة السنة الخمسية بنجاح 💰'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text(isEdit ? 'تعديل' : 'إضافة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRecord(Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف سجل السنة الخمسية'),
          content: Text('هل أنت أتقن من حذف سجل "${record['year_title']}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteKhumsRecord(record['id'] as int);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف السجل بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _generateKhumsReportText() {
    final buffer = StringBuffer();
    buffer.writeln('💰 *تقرير رأس المال والمحاسبة الخمسية*');
    buffer.writeln('تاريخ التقرير: ${DateTime.now().toIso8601String().split('T').first}');
    buffer.writeln('==========================================');

    final dateStr = _khumsInfo?['fiscal_year_date'] as String? ?? 'غير محدد';
    buffer.writeln('📅 *تاريخ رأس السنة الخمسية:* $dateStr');
    if (_khumsInfo?['notes'] != null && _khumsInfo!['notes'].toString().isNotEmpty) {
      buffer.writeln('📝 *توجيهات وملاحظات رأس السنة:* ${_khumsInfo!['notes']}');
    }
    buffer.writeln();

    buffer.writeln('📊 *سجل السنوات الخمسية ورأس المال المخمّس:*');
    if (_khumsRecords.isEmpty) {
      buffer.writeln('• لا توجد سنوات خمسية مسجلة بعد.');
    } else {
      for (int i = 0; i < _khumsRecords.length; i++) {
        final item = _khumsRecords[i];
        buffer.writeln('─────────────── [${item['year_title']}] ───────────────');
        buffer.writeln('تاريخ المحاسبة: ${item['khums_date']}');
        buffer.writeln('رأس المال المخمّس: ${item['taxed_capital']} ${item['currency']}');
        if (item['khums_paid'] != null && (item['khums_paid'] as num) > 0) {
          buffer.writeln('الخمس المدفوع: ${item['khums_paid']} ${item['currency']}');
        }
        if (item['assets_detail'] != null && item['assets_detail'].toString().isNotEmpty) {
          buffer.writeln('الممتلكات والأصول المخمسة:\n${item['assets_detail']}');
        }
        if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
          buffer.writeln('ملاحظات: ${item['notes']}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('==========================================');
    buffer.writeln('تطبيق قضاء - لتوثيق المحاسبة الخمسية والحقوق المالـية.');
    return buffer.toString();
  }

  void _showReportDialog() {
    final reportText = _generateKhumsReportText();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.description, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text('تقرير المحاسبة الخمسية 📜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  reportText,
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
                    reportText,
                    'تم نسخ تقرير الخمس إلى الحافظة',
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('نسخ التقرير'),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.printDocument(
                    title: 'تقرير المحاسبة الخمسية ورأس المال',
                    content: reportText,
                  ),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('طباعة التقرير'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.shareToWhatsApp(reportText),
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
                    title: 'تقرير المحاسبة الخمسية ورأس المال',
                    content: reportText,
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
    final fiscalYearDate = _khumsInfo?['fiscal_year_date'] as String? ?? '';
    final fiscalNotes = _khumsInfo?['notes'] as String? ?? '';

    double latestTaxedCapital = 0.0;
    String latestCurrency = 'د.ع';
    if (_khumsRecords.isNotEmpty) {
      latestTaxedCapital = (_khumsRecords.first['taxed_capital'] as num?)?.toDouble() ?? 0.0;
      latestCurrency = _khumsRecords.first['currency'] as String? ?? 'د.ع';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('المحاسبة الخمسية ورأس المال', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'طباعة وتصدير التقرير',
              onPressed: _showReportDialog,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddOrEditRecordDialog(),
          backgroundColor: const Color(0xFF0F766E),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('إضافة سنة خمسية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card: Fiscal Year Date
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_month, color: Colors.amberAccent, size: 26),
                                  SizedBox(width: 8),
                                  Text(
                                    'تاريخ رأس السنة الخمسية',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                tooltip: 'تعديل تاريخ رأس السنة',
                                onPressed: _showEditFiscalYearDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            fiscalYearDate.isNotEmpty ? fiscalYearDate : 'لم يتم تحديد تاريخ رأس السنة الخمسية بعد',
                            style: TextStyle(
                              color: fiscalYearDate.isNotEmpty ? Colors.amberAccent : Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (fiscalNotes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'ملاحظة: $fiscalNotes',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Summary Stat Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Color(0xFF0F766E), size: 20),
                                    SizedBox(width: 6),
                                    Text('آخر رأس مال مخمّس', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${latestTaxedCapital.toStringAsFixed(0)} $latestCurrency',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.history, color: Color(0xFFD97706), size: 20),
                                    SizedBox(width: 6),
                                    Text('السنوات المسجلة', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_khumsRecords.length} سنة',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'سجل المحاسبات والممتلكات المخمسة 📜',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        TextButton.icon(
                          onPressed: _showReportDialog,
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('مشاركة السجل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Records List
                    if (_khumsRecords.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'لم تقم بإضافة أي سنة خمسية حتى الآن',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'اضغط على زر "إضافة سنة خمسية" لتسجيل رأس المال والممتلكات المخمّسة لكل عام.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _khumsRecords.length,
                        itemBuilder: (context, index) {
                          final item = _khumsRecords[index];
                          final capital = (item['taxed_capital'] as num?)?.toDouble() ?? 0.0;
                          final paid = (item['khums_paid'] as num?)?.toDouble() ?? 0.0;
                          final currency = item['currency'] as String? ?? 'د.ع';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
                                              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.workspace_premium, color: Color(0xFF0F766E)),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['year_title'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                              ),
                                              Text(
                                                'تاريخ المحاسبة: ${item['khums_date']}',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0F766E), size: 20),
                                            onPressed: () => _showAddOrEditRecordDialog(item),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () => _confirmDeleteRecord(item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  // Taxed Capital
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Row(
                                            children: [
                                              Icon(Icons.shield, color: Color(0xFF059669), size: 20),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'رأس المال المخمّس (المحمّي):',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${capital.toStringAsFixed(0)} $currency',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Khums Paid if available
                                  if (paid > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Color(0xFF0F766E), size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'مقدار الخمس المدفوع: ${paid.toStringAsFixed(0)} $currency',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Assets Detail
                                  if (item['assets_detail'] != null && item['assets_detail'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      '🏠 الممتلكات والأصول المخمّسة وقيمتها:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: SelectableText(
                                        item['assets_detail'],
                                        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],

                                  // Notes
                                  if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '📝 ملاحظات: ${item['notes']}',
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
