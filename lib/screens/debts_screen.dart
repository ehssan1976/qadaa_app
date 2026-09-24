import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../utils/print_and_share_helper.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Map<String, dynamic>> _debts = [];
  bool _isLoading = true;
  String _filterType = 'ALL'; // 'ALL', 'OWED', 'LENT', 'SETTLED'

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getDebts();
      if (mounted) {
        setState(() {
          _debts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading debts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalOwedActive {
    return _debts
        .where((d) => d['type'] == 'OWED' && (d['is_settled'] ?? 0) == 0)
        .fold(0.0, (sum, d) => sum + (double.tryParse(d['amount'].toString()) ?? 0.0));
  }

  double get _totalLentActive {
    return _debts
        .where((d) => d['type'] == 'LENT' && (d['is_settled'] ?? 0) == 0)
        .fold(0.0, (sum, d) => sum + (double.tryParse(d['amount'].toString()) ?? 0.0));
  }

  List<Map<String, dynamic>> get _filteredDebts {
    if (_filterType == 'OWED') {
      return _debts.where((d) => d['type'] == 'OWED' && (d['is_settled'] ?? 0) == 0).toList();
    } else if (_filterType == 'LENT') {
      return _debts.where((d) => d['type'] == 'LENT' && (d['is_settled'] ?? 0) == 0).toList();
    } else if (_filterType == 'SETTLED') {
      return _debts.where((d) => (d['is_settled'] ?? 0) == 1).toList();
    }
    return _debts;
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }

  Future<void> _showDebtDialog({Map<String, dynamic>? debtToEdit}) async {
    final isEditing = debtToEdit != null;
    final nameController = TextEditingController(text: debtToEdit?['person_name'] ?? '');
    final phoneController = TextEditingController(text: debtToEdit?['phone_number'] ?? '');
    final amountController = TextEditingController(
      text: debtToEdit != null ? debtToEdit['amount'].toString() : '',
    );
    final notesController = TextEditingController(text: debtToEdit?['notes'] ?? '');

    String type = debtToEdit?['type'] ?? 'OWED'; // 'OWED' (عليّ) or 'LENT' (لي)
    String currency = debtToEdit?['currency'] ?? 'د.ع';
    String dateStr = debtToEdit?['date'] ?? DateTime.now().toIso8601String().split('T').first;
    String? dueDateStr = debtToEdit?['due_date'];

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
                            isEditing ? 'تعديل سجل الدين / القرض' : 'إضافة سجل دين أو قرض جديد',
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
                      const SizedBox(height: 16),

                      // Segmented Button / Type selector
                      const Text(
                        'تصنيف السجل:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text(
                                  'ديون عليّ (تداينتها من الغير)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              selected: type == 'OWED',
                              selectedColor: const Color(0xFFEF4444),
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: type == 'OWED' ? Colors.white : const Color(0xFF334155),
                                fontSize: 12.5,
                              ),
                              onSelected: (val) {
                                if (val) setModalState(() => type = 'OWED');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text(
                                  'ديون لي (أقرضتها للغير)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              selected: type == 'LENT',
                              selectedColor: const Color(0xFF0F766E),
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: type == 'LENT' ? Colors.white : const Color(0xFF334155),
                                fontSize: 12.5,
                              ),
                              onSelected: (val) {
                                if (val) setModalState(() => type = 'LENT');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الشخص أو الجهة *',
                          hintText: 'مثال: أبو أحمد / أحمد علي',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة اسم الشخص' : null,
                      ),
                      const SizedBox(height: 14),

                      // Amount & Currency Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'المبلغ *',
                                hintText: 'مثال: 50000',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'يرجى أدخال المبلغ';
                                if (double.tryParse(val.trim()) == null) return 'مبلغ غير صحيح';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: currency,
                              decoration: const InputDecoration(
                                labelText: 'العملة',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'د.ع', child: Text('د.ع (دينار)')),
                                DropdownMenuItem(value: '\$', child: Text('\$ (دولار)')),
                                DropdownMenuItem(value: 'ر.س', child: Text('ر.س (ريال)')),
                                DropdownMenuItem(value: 'ج.م', child: Text('ج.م (جنيه)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => currency = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Phone Field
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          hintText: '07700000000',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date Pickers
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2050),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    dateStr = picked.toIso8601String().split('T').first;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ الدين',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                ),
                                child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2050),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    dueDateStr = picked.toIso8601String().split('T').first;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'تاريخ الاستحقاق',
                                  prefixIcon: const Icon(Icons.event_available_outlined),
                                  suffixIcon: dueDateStr != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () => setModalState(() => dueDateStr = null),
                                        )
                                      : null,
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                ),
                                child: Text(
                                  dueDateStr ?? 'غير محدد',
                                  style: TextStyle(
                                    fontWeight: dueDateStr != null ? FontWeight.bold : FontWeight.normal,
                                    color: dueDateStr != null ? const Color(0xFF0F766E) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes Field
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات / وصية خاصة بالدين (اختياري)',
                          hintText: 'تفاصيل إضافية أو مكان السداد لتكون مرجعاً للورثة...',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final data = {
                                'person_name': nameController.text.trim(),
                                'phone_number': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                                'amount': double.parse(amountController.text.trim()),
                                'currency': currency,
                                'type': type,
                                'date': dateStr,
                                'due_date': dueDateStr,
                                'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                'is_settled': debtToEdit?['is_settled'] ?? 0,
                                'settled_date': debtToEdit?['settled_date'],
                              };

                              if (isEditing) {
                                await DatabaseHelper.instance.updateDebt(debtToEdit['id'], data);
                              } else {
                                await DatabaseHelper.instance.insertDebt(data);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadDebts();
                              HapticFeedback.mediumImpact();
                            }
                          },
                          icon: Icon(isEditing ? Icons.save : Icons.add_circle, color: Colors.white),
                          label: Text(
                            isEditing ? 'حفظ التعديلات' : 'حفظ سجل الدين',
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

  void _showLegacyStatementDialog() {
    final activeOwed = _debts.where((d) => d['type'] == 'OWED' && (d['is_settled'] ?? 0) == 0).toList();
    final activeLent = _debts.where((d) => d['type'] == 'LENT' && (d['is_settled'] ?? 0) == 0).toList();

    final buffer = StringBuffer();
    buffer.writeln('📜 *بيان الحقوق والديون المالية (وصية ومرجع للورثة)*');
    buffer.writeln('تاريخ الاستخراج: ${DateTime.now().toIso8601String().split('T').first}');
    buffer.writeln('------------------------------------------');
    buffer.writeln();

    buffer.writeln('🔴 *أولاً: الديون التي عليّ للغير (يجب تسديدها من التركة):*');
    if (activeOwed.isEmpty) {
      buffer.writeln('• لا توجد ديون مسجلة على ذمتي للغير بحمد الله.');
    } else {
      for (int i = 0; i < activeOwed.length; i++) {
        final item = activeOwed[i];
        buffer.writeln('${i + 1}. ${item['person_name']} - المبلغ: ${_formatAmount(double.parse(item['amount'].toString()))} ${item['currency']}');
        if (item['phone_number'] != null && item['phone_number'].toString().isNotEmpty) {
          buffer.writeln('   هاتف: ${item['phone_number']}');
        }
        buffer.writeln('   تاريخ الدين: ${item['date']}');
        if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
          buffer.writeln('   ملاحظة: ${item['notes']}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('🟢 *ثانياً: الديون التي لي على الغير (تستحصل للورثة):*');
    if (activeLent.isEmpty) {
      buffer.writeln('• لا توجد ديون لي على الآخرين مسجلة.');
    } else {
      for (int i = 0; i < activeLent.length; i++) {
        final item = activeLent[i];
        buffer.writeln('${i + 1}. ${item['person_name']} - المبلغ: ${_formatAmount(double.parse(item['amount'].toString()))} ${item['currency']}');
        if (item['phone_number'] != null && item['phone_number'].toString().isNotEmpty) {
          buffer.writeln('   هاتف: ${item['phone_number']}');
        }
        buffer.writeln('   تاريخ القرض: ${item['date']}');
        if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
          buffer.writeln('   ملاحظة: ${item['notes']}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('------------------------------------------');
    buffer.writeln('نسأل الله حسنة الخاتمة والمغفرة والتجاوز.');

    final statementText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text('بيان الذمة المالية للورثة 📜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  statementText,
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
                    statementText,
                    'تم نسخ البيان إلى الحافظة بنجاح',
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('نسخ البيان'),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.printDocument(
                    title: 'بيان الديون والحقوق المالية للورثة',
                    content: statementText,
                  ),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('طباعة البيان'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintAndShareHelper.shareToWhatsApp(statementText),
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
                    title: 'بيان الديون والحقوق المالية للورثة',
                    content: statementText,
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

  Future<void> _confirmToggleSettled(Map<String, dynamic> item) async {
    final isSettled = (item['is_settled'] ?? 0) == 1;
    final personName = item['person_name'] ?? '';
    final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
    final currency = item['currency'] ?? 'د.ع';

    final title = isSettled ? 'إلغاء تسديد الدين' : 'تأكيد تسديد الدين وإبراء الذمة';
    final content = isSettled
        ? 'هل ترغب في إرجاع سجل ($personName) بمبلغ (${_formatAmount(amount)} $currency) إلى قائمة الديون النشطة؟'
        : 'هل أنت تأكد من تثبيت تسديد دين ($personName) بمبلغ (${_formatAmount(amount)} $currency) وإبراء الذمة؟';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isSettled ? Icons.restore : Icons.check_circle_outline,
                color: isSettled ? Colors.orange : const Color(0xFF0F766E),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(content, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSettled ? Colors.orange : const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isSettled ? 'نعم، إلغاء التسديد' : 'تأكيد التسديد'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.toggleDebtSettled(item['id'], !isSettled);
      _loadDebts();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'سجل الديون والقروض',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'إصدار بيان للورثة',
              onPressed: _showLegacyStatementDialog,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showDebtDialog(),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة دين / قرض', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
            : RefreshIndicator(
                onRefresh: _loadDebts,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Summary Header Card
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
                            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_downward, color: Colors.redAccent, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'ديون عليّ (يطلبني)',
                                            style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      FittedBox(
                                        child: Text(
                                          '${_formatAmount(_totalOwedActive)} د.ع',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_upward, color: Colors.amberAccent, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'ديون لي (أطلبها)',
                                            style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      FittedBox(
                                        child: Text(
                                          '${_formatAmount(_totalLentActive)} د.ع',
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _showLegacyStatementDialog,
                            icon: const Icon(Icons.assignment_outlined, color: Colors.amberAccent, size: 18),
                            label: const Text(
                              'عرض وثيقة الذمة المالية للورثة 📜',
                              style: TextStyle(color: Colors.amberAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amberAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('الكـل'),
                            selected: _filterType == 'ALL',
                            selectedColor: const Color(0xFF0F766E),
                            labelStyle: TextStyle(
                              color: _filterType == 'ALL' ? Colors.white : const Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _filterType = 'ALL');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('ديون عليّ (غير مسددة)'),
                            selected: _filterType == 'OWED',
                            selectedColor: Colors.redAccent,
                            labelStyle: TextStyle(
                              color: _filterType == 'OWED' ? Colors.white : const Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _filterType = 'OWED');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('ديون لي (غير مسددة)'),
                            selected: _filterType == 'LENT',
                            selectedColor: const Color(0xFF0F766E),
                            labelStyle: TextStyle(
                              color: _filterType == 'LENT' ? Colors.white : const Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _filterType = 'LENT');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('المسددة ✔'),
                            selected: _filterType == 'SETTLED',
                            selectedColor: Colors.grey.shade700,
                            labelStyle: TextStyle(
                              color: _filterType == 'SETTLED' ? Colors.white : const Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _filterType = 'SETTLED');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (_filteredDebts.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _filterType == 'SETTLED'
                                  ? 'لا توجد ديون مسددة بعد'
                                  : 'لا توجد ديون أو قروض مسجلة في هذا الفرز',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'اضغط على "+ إضافة دين / قرض" لتسجيل حقك أو دينك',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._filteredDebts.map((item) {
                        final isSettled = (item['is_settled'] ?? 0) == 1;
                        final isOwed = item['type'] == 'OWED'; // عليّ
                        final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
                        final currency = item['currency'] ?? 'د.ع';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isSettled ? 0.5 : 2,
                          color: isSettled
                              ? Colors.grey.shade50
                              : (isOwed ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDFA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSettled
                                  ? Colors.grey.shade300
                                  : (isOwed ? const Color(0xFFFCA5A5) : const Color(0xFF99F6E4)),
                              width: isSettled ? 1 : 1.5,
                            ),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSettled
                                                ? Colors.grey.shade400
                                                : (isOwed ? Colors.red.shade600 : const Color(0xFF0F766E)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isSettled
                                                ? 'مسدد ✔'
                                                : (isOwed ? 'عليّ (يطلبني)' : 'لي (أطلبه)'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item['person_name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            decoration: isSettled ? TextDecoration.lineThrough : null,
                                            color: isSettled ? Colors.grey.shade600 : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${_formatAmount(amount)} $currency',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: isSettled
                                            ? Colors.grey
                                            : (isOwed ? Colors.red.shade700 : const Color(0xFF0F766E)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Phone number row
                                if (item['phone_number'] != null && item['phone_number'].toString().isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['phone_number'].toString(),
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // Dates Row
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'التاريخ: ${item['date']}',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                    ),
                                    if (item['due_date'] != null && item['due_date'].toString().isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      const Icon(Icons.event_outlined, size: 13, color: Color(0xFFD97706)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'الاستحقاق: ${item['due_date']}',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),

                                // Notes Row
                                if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.note_alt_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['notes'].toString(),
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 6),

                                // Action Row with Settlement Confirmation Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmToggleSettled(item),
                                      icon: Icon(
                                        isSettled ? Icons.restore : Icons.task_alt,
                                        size: 16,
                                      ),
                                      label: Text(
                                        isSettled ? 'مسدد (إلغاء)' : 'تثبيت التسديد',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSettled ? Colors.grey.shade400 : const Color(0xFF0F766E),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          color: const Color(0xFF0F766E),
                                          tooltip: 'تعديل السجل',
                                          onPressed: () => _showDebtDialog(debtToEdit: item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          color: Colors.redAccent,
                                          tooltip: 'حذف السجل',
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => Directionality(
                                                textDirection: TextDirection.rtl,
                                                child: AlertDialog(
                                                  title: const Text('حذف سجل الدين'),
                                                  content: Text('هل أنت تأكد من حذف سجل (${item['person_name']})؟'),
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
                                              await DatabaseHelper.instance.deleteDebt(item['id']);
                                              _loadDebts();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
