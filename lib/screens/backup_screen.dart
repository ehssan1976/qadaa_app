import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isProcessing = false;

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _isProcessing = true);
    try {
      final file = await DatabaseHelper.instance.createBackupFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'نسخة احتياطية - تطبيق قضاء العبادات',
        text: 'ملف النسخة الاحتياطية لبيانات الصلوات والصيام.',
      );
    } catch (e) {
      _showFeedback('حدث خطأ أثناء تصدير النسخة الاحتياطية', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الاسترجاع'),
            content: const Text(
              'استرجاع هذه النسخة سيستبدل البيانات الحالية على الهاتف بالبيانات الموجودة في الملف. هل تود المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('تأكيد الاستبدال'),
              ),
            ],
          ),
        ),
      );

      if (confirm == true) {
        setState(() => _isProcessing = true);
        try {
          final file = File(result.files.single.path!);
          final content = await file.readAsString();
          final success = await DatabaseHelper.instance.restoreDatabaseFromJson(
            content,
          );

          if (success) {
            _showFeedback('تم استرجاع البيانات بنجاح');
          } else {
            _showFeedback('الملف المحدد غير صالح أو تالف', isError: true);
          }
        } catch (e) {
          _showFeedback('فشل استيراد الملف', isError: true);
        } finally {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text(
            'النسخ الاحتياطي والبيانات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F766E)),
              )
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF0F766E),
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'جميع بياناتك مخزنة محلياً على هاتفك للحفاظ على الخصوصية. يمكنك تصدير نسخة وحفظها واسترجاعها في أي وقت.',
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
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE6F4EA),
                        child: Icon(
                          Icons.file_upload_outlined,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      title: const Text(
                        'تصدير نسخة احتياطية',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'حفظ ومشاركة ملف JSON يحتوي على كل صلواتك وصيامك المنجز',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: _exportBackup,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      title: const Text(
                        'استيراد نسخة احتياطية',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'استرجاع بياناتك السابقة من ملف محفوظ مسبقاً على الجهاز',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: _importBackup,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
