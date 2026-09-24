import 'dart:html' as html;

void printHtmlDocument(String title, String rawContent) {
  try {
    final safeContent = rawContent
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    final htmlContent = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;600;700&display=swap');
    * { box-sizing: border-box; }
    body {
      font-family: 'Tajawal', 'Segoe UI', Tahoma, Arial, sans-serif;
      padding: 30px;
      direction: rtl;
      color: #1e293b;
      background-color: #ffffff;
      max-width: 850px;
      margin: 0 auto;
    }
    .print-bar {
      margin-bottom: 25px;
      text-align: center;
      background: #f1f5f9;
      padding: 12px;
      border-radius: 10px;
      border: 1px solid #cbd5e1;
    }
    .print-btn {
      background: #0f766e;
      color: white;
      border: none;
      padding: 12px 30px;
      border-radius: 8px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      box-shadow: 0 4px 6px -1px rgba(15, 118, 110, 0.3);
      transition: background 0.2s;
    }
    .print-btn:hover {
      background: #0d655e;
    }
    .header {
      text-align: center;
      border-bottom: 2px solid #0f766e;
      padding-bottom: 15px;
      margin-bottom: 25px;
    }
    .header h1 {
      color: #0f766e;
      margin: 0 0 8px 0;
      font-size: 24px;
      font-weight: 700;
    }
    .header p {
      color: #64748b;
      font-size: 14px;
      margin: 0;
    }
    .content-box {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 25px;
      font-size: 15px;
      line-height: 1.8;
      white-space: pre-wrap;
      word-break: break-word;
    }
    .footer {
      margin-top: 35px;
      text-align: center;
      font-size: 13px;
      color: #94a3b8;
      border-top: 1px solid #e2e8f0;
      padding-top: 15px;
    }
    @media print {
      .print-bar { display: none !important; }
      body { padding: 0; max-width: 100%; }
      .content-box { border: none; background: transparent; padding: 0; }
    }
  </style>
</head>
<body>
  <div class="print-bar">
    <button class="print-btn" onclick="window.print()">🖨️ طباعة المستند الآن / حفظ PDF</button>
  </div>
  <div class="header">
    <h1>$title</h1>
    <p>وثيقة رسمية صادرة من تطبيق قضاء لتوثيق الواجبات والحقوق الشرعية</p>
  </div>
  <div class="content-box">$safeContent</div>
  <div class="footer">
    تم استخراج هذا السند من تطبيق (قضاء) بتاريخ: ${DateTime.now().toString().split(' ').first}
  </div>
  <script>
    setTimeout(function() { window.print(); }, 400);
  </script>
</body>
</html>
''';

    final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final win = html.window.open(url, '_blank');
    if (win == null) {
      html.window.print();
    }
  } catch (_) {
    try {
      html.window.print();
    } catch (_) {}
  }
}
