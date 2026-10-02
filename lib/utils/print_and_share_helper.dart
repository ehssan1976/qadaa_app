import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'document_printer_stub.dart'
    if (dart.library.html) 'document_printer_web.dart';

class PrintAndShareHelper {
  static const MethodChannel _printChannel = MethodChannel('com.example.qadaa_app/print');

  /// Builds a beautifully formatted HTML document ready for printing or previewing
  static String buildHtmlDocument({
    required String title,
    required String content,
    bool isForWeb = false,
  }) {
    final safeContent = content
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    final today = DateTime.now().toString().split(' ').first;

    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;600;700&display=swap');
    * { box-sizing: border-box; }
    body {
      font-family: 'Tajawal', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      padding: 24px;
      direction: rtl;
      color: #1e293b;
      background-color: #ffffff;
      max-width: 850px;
      margin: 0 auto;
      font-size: 14.5px;
      line-height: 1.8;
    }
    .header {
      text-align: center;
      border-bottom: 2px solid #0f766e;
      padding-bottom: 15px;
      margin-bottom: 20px;
    }
    .header h1 {
      color: #0f766e;
      margin: 0 0 8px 0;
      font-size: 22px;
      font-weight: 700;
    }
    .header p {
      color: #64748b;
      font-size: 13px;
      margin: 0;
    }
    .content-box {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 20px;
      white-space: pre-wrap;
      word-break: break-word;
      font-size: 14px;
      line-height: 1.8;
    }
    .footer {
      margin-top: 30px;
      text-align: center;
      font-size: 12px;
      color: #94a3b8;
      border-top: 1px solid #e2e8f0;
      padding-top: 15px;
    }
    @media print {
      body { padding: 0; max-width: 100%; }
      .content-box { border: none; background: transparent; padding: 0; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>$title</h1>
    <p>وثيقة رسمية صادرة من تطبيق قضاء لتوثيق الواجبات والحقوق الشرعية</p>
  </div>
  <div class="content-box">$safeContent</div>
  <div class="footer">
    تم استخراج هذا السند من تطبيق (قضاء) بتاريخ: $today
  </div>
  ${isForWeb ? '<script>setTimeout(function() { window.print(); }, 400);</script>' : ''}
</body>
</html>
''';
  }

  /// Triggers document printing across all platforms:
  /// - Web: browser print dialog
  /// - Android: native Android PrintManager (supporting WiFi/BT printers and Save as PDF)
  /// - Other platforms: open/share HTML document
  static Future<void> printDocument({
    required String title,
    required String content,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      printHtmlDocument(title, content);
      return;
    }

    final htmlContent = buildHtmlDocument(title: title, content: content, isForWeb: false);

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? success = await _printChannel.invokeMethod<bool>('printHtml', {
          'title': title,
          'html': htmlContent,
        });
        if (success == true) return;
      } catch (e) {
        debugPrint('Android PrintManager error: $e');
      }
    }

    // Fallback: save to temp file and open or share
    try {
      final tempDir = await getTemporaryDirectory();
      final safeName = title.replaceAll(RegExp(r'[^\w\u0600-\u06FF\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      final fileName = safeName.isNotEmpty ? safeName : 'document';
      final file = File('${tempDir.path}/$fileName.html');
      await file.writeAsString(htmlContent);

      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }

      await Share.shareXFiles([XFile(file.path, mimeType: 'text/html')], text: title);
    } catch (e) {
      debugPrint('Fallback document print error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح نافذة الطباعة: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Direct WhatsApp share link
  static Future<void> shareToWhatsApp(String text) async {
    final whatsappUrl = Uri.parse(
      'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      final waMeUrl = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(text)}',
      );
      await launchUrl(waMeUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Shares document via system share, or WhatsApp as fallback
  static Future<void> shareDocument({
    required BuildContext context,
    required String title,
    required String content,
  }) async {
    try {
      await Share.share(content, subject: title);
    } catch (_) {
      await shareToWhatsApp(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم توجيه المشاركة عبر واتساب بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Copies content to clipboard with snackbar feedback
  static void copyToClipboard(BuildContext context, String content, String successMessage) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
