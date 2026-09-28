import 'dart:async';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SmsOtpDialog extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const SmsOtpDialog({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String phoneNumber,
    required String verificationId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmsOtpDialog(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
      ),
    );
  }

  @override
  State<SmsOtpDialog> createState() => _SmsOtpDialogState();
}

class _SmsOtpDialogState extends State<SmsOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'يرجى إدخال رمز التحقق (SMS) المكون من 6 أرقام كاملة.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithSmsCode(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Header Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sms_outlined,
              size: 44,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'تأكيد كود الرسالة SMS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'أدخل رمز التحقق المكون من 6 أرقام المرسل عبر رسالة نصية قصيرة (SMS) إلى الرقم:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),

          // Phone Badge
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_android, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error Message Banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // OTP Input TextField
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 26,
              letterSpacing: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: TextStyle(
                letterSpacing: 8,
                color: Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
              ),
            ),
            onSubmitted: (_) => _verifyOtp(),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'تأكيد الدخول الحساب',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Timer / Resend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _resendSeconds > 0
                    ? 'يمكن طلب رمز جديد بعد ($_resendSeconds ثانية)'
                    : 'إذا لم تصلك الرسالة، اضغط لإعادة المحاولة',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
