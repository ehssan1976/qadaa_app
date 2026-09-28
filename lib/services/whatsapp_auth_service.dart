import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Provider types for WhatsApp messaging
enum WhatsAppApiProvider {
  metaCloudApi, // Meta WhatsApp Business Cloud API (Official)
  twilio,       // Twilio WhatsApp API
  customGateway // Custom Webhook / Cloud Function / UltraMsg
}

class WhatsAppAuthService {
  WhatsAppAuthService._privateConstructor();
  static final WhatsAppAuthService instance = WhatsAppAuthService._privateConstructor();

  // Configuration settings (Replace with your Meta/Twilio credentials when ready)
  WhatsAppApiProvider provider = WhatsAppApiProvider.metaCloudApi;

  // Meta WhatsApp Cloud API credentials
  String metaPhoneNumberId = 'YOUR_META_PHONE_NUMBER_ID';
  String metaAccessToken = 'YOUR_META_PERMANENT_ACCESS_TOKEN';
  String metaTemplateName = 'auth_otp_code'; // Default template name in Meta Manager

  // Custom Gateway / Cloud Function URL
  String customGatewayUrl = 'https://your-api-endpoint.com/api/send-whatsapp-otp';

  // In-memory OTP storage: phone -> {code, expiryTimestamp}
  final Map<String, _OTPData> _otpStore = {};

  /// Generate a random 6-digit OTP code
  String _generate6DigitOTP() {
    final random = Random();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// Format phone number to clean E.164 standard (e.g. +9647701234567 -> 9647701234567)
  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// Check if Meta API keys are in test/simulation mode
  bool isTestModeActive() {
    return metaPhoneNumberId.contains('YOUR_META') ||
        metaAccessToken.contains('YOUR_META');
  }

  /// Get current active OTP code for phone (useful in simulation/test mode)
  String? getOtpCode(String phoneNumber) {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    final data = _otpStore[cleanPhone];
    if (data != null && DateTime.now().isBefore(data.expiry)) {
      return data.code;
    }
    return null;
  }

  /// Send a real OTP message via WhatsApp API to the user's phone number
  Future<bool> sendWhatsAppOTP(String phoneNumber) async {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    if (cleanPhone.length < 8) {
      throw 'رقم الهاتف غير صحيح. يرجى إدخال رقم هاتف مكتمل مع فتح الخط الدولي.';
    }

    // Generate 6-digit OTP code
    final otpCode = _generate6DigitOTP();
    // Expiration time: 5 minutes from now
    final expiry = DateTime.now().add(const Duration(minutes: 5));
    _otpStore[cleanPhone] = _OTPData(code: otpCode, expiry: expiry);

    debugPrint('💬 [WhatsAppAuth] Generated OTP: $otpCode for phone: +$cleanPhone');

    // Check if configuration credentials are placeholder/empty
    final bool isTestMode = metaPhoneNumberId.contains('YOUR_META') ||
        metaAccessToken.contains('YOUR_META');

    if (isTestMode) {
      debugPrint('⚠️ [WhatsAppAuth] running in Test/Simulation Mode. OTP is: $otpCode');
      // In test mode, we simulate successful network request
      await Future.delayed(const Duration(milliseconds: 1200));
      return true;
    }

    // Send via selected Provider
    try {
      if (provider == WhatsAppApiProvider.metaCloudApi) {
        return await _sendViaMetaCloudApi(cleanPhone, otpCode);
      } else if (provider == WhatsAppApiProvider.customGateway) {
        return await _sendViaCustomGateway(cleanPhone, otpCode);
      } else {
        throw 'مزود الخدمة غير مدعوم حالياً.';
      }
    } catch (e) {
      debugPrint('❌ [WhatsAppAuth] Error sending WhatsApp message: $e');
      throw 'تعذر إرسال كود التفعيل عبر الواتساب: $e';
    }
  }

  /// Send OTP via Meta WhatsApp Business Cloud API (Official)
  Future<bool> _sendViaMetaCloudApi(String phone, String otpCode) async {
    final url = Uri.parse(
      'https://graph.facebook.com/v19.0/$metaPhoneNumberId/messages',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $metaAccessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': phone,
        'type': 'template',
        'template': {
          'name': metaTemplateName,
          'language': {'code': 'ar'},
          'components': [
            {
              'type': 'body',
              'parameters': [
                {'type': 'text', 'text': otpCode}
              ]
            },
            {
              'type': 'button',
              'sub_type': 'url',
              'index': 0,
              'parameters': [
                {'type': 'text', 'text': otpCode}
              ]
            }
          ]
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ [WhatsAppAuth] Message sent via Meta Cloud API successfully');
      return true;
    } else {
      final body = jsonDecode(response.body);
      final errorMsg = body['error']?['message'] ?? response.body;
      throw 'خطأ من سيرفر واتساب Meta: $errorMsg';
    }
  }

  /// Send OTP via Custom Gateway / Webhook
  Future<bool> _sendViaCustomGateway(String phone, String otpCode) async {
    final response = await http.post(
      Uri.parse(customGatewayUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'code': otpCode,
        'message': 'رمز التحقق الخاص بك في تطبيق قضاء هو: $otpCode',
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw 'فشل الإرسال عبر البوابة الخاصة (${response.statusCode})';
    }
  }

  /// Verify the OTP entered by user
  Future<bool> verifyWhatsAppOTP({
    required String phoneNumber,
    required String enteredCode,
  }) async {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    final otpData = _otpStore[cleanPhone];

    if (otpData == null) {
      throw 'لم يتم العثور على طلب تفعيل لهذا الرقم. يرجى إعادة إرسال الكود.';
    }

    if (DateTime.now().isAfter(otpData.expiry)) {
      _otpStore.remove(cleanPhone);
      throw 'انتهت صلاحية كود التحقق. يرجى طلب كود جديد.';
    }

    if (otpData.code.trim() == enteredCode.trim()) {
      // Code is valid! Remove from memory
      _otpStore.remove(cleanPhone);
      return true;
    } else {
      throw 'كود التحقق غير صحيح. يرجى التأكد وإعادة المحاولة.';
    }
  }
}

class _OTPData {
  final String code;
  final DateTime expiry;

  _OTPData({required this.code, required this.expiry});
}
