import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'document_printer_stub.dart'
    if (dart.library.html) 'document_printer_web.dart';

class PrintAndShareHelper {
  /// Opens a clean, formatted HTML document view and triggers printing.
  static void printDocument({
    required String title,
    required String content,
  }) {
    if (kIsWeb) {
      printHtmlDocument(title, content);
    } else {
      final Uri dataUri = Uri.parse(
        'data:text/html;charset=utf-8,${Uri.encodeComponent('''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    body { font-family: sans-serif; padding: 20px; direction: rtl; }
    .btn { background: #0f766e; color: white; border: none; padding: 10px 20px; font-size: 16px; border-radius: 5px; cursor: pointer; }
    @media print { .btn { display: none; } }
  </style>
</head>
<body>
  <button class="btn" onclick="window.print()">طباعة المستند</button>
  <h2>$title</h2>
  <pre style="white-space: pre-wrap; font-family: inherit;">$content</pre>
  <script>window.print();</script>
</body>
</html>
''')}',
      );
      launchUrl(dataUri, mode: LaunchMode.externalApplication).catchError((_) => false);
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
