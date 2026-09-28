import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/whatsapp_auth_service.dart';

class WhatsAppOtpDialog extends StatefulWidget {
  final String phoneNumber;
  final String? simulatedCode; // Passed in test mode for easy developer testing

  const WhatsAppOtpDialog({
    super.key,
    required this.phoneNumber,
    this.simulatedCode,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String phoneNumber,
    String? simulatedCode,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppOtpDialog(
        phoneNumber: phoneNumber,
        simulatedCode: simulatedCode,
      ),
    );
  }

  @override
  State<WhatsAppOtpDialog> createState() => _WhatsAppOtpDialogState();
}

class _WhatsAppOtpDialogState extends State<WhatsAppOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  // Countdown timer for resend
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-fill in debug simulation if code provided
    if (widget.simulatedCode != null) {
      _otpController.text = widget.simulatedCode!;
    }
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
    if (code.length < 4) {
      setState(() {
        _errorMessage = 'يرجى إدخال كود التحقق المكون من 6 أرقام كاملة.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await WhatsAppAuthService.instance.verifyWhatsAppOTP(
        phoneNumber: widget.phoneNumber,
        enteredCode: code,
      );

      if (mounted) {
        if (isValid) {
          Navigator.of(context).pop(true); // Return true on successful verification
        }
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

  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await WhatsAppAuthService.instance.sendWhatsAppOTP(widget.phoneNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة إرسال كود التحقق على الواتساب بنجاح'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _openWhatsAppDirectly() async {
    final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final code = widget.simulatedCode ?? WhatsAppAuthService.instance.getOtpCode(widget.phoneNumber) ?? '';
    final message = Uri.encodeComponent('رمز التوثيق الخاص بك في تطبيق قضاء هو: $code');
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$message'), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر فتح تطبيق الواتساب: $e';
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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Header with WhatsApp Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 44,
              color: Color(0xFF25D366),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'تأكيد كود الواتساب',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'أدخل رمز التحقق المكون من 6 أرقام الذي تم إرساله إلى حسابك في الواتساب:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),

          // Phone badge
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
                  const Icon(Icons.phone_android, size: 16, color: Color(0xFF25D366)),
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

          // Test Mode Banner if active
          if (widget.simulatedCode != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'وضع التجربة الفوري: كود التفعيل هو [ ${widget.simulatedCode} ]',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Error message banner
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

          // OTP Input Field
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
                borderSide: const BorderSide(color: Color(0xFF25D366), width: 2),
              ),
            ),
            onSubmitted: (_) => _verifyOtp(),
          ),
          const SizedBox(height: 20),

          // Submit Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
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
                          'تأكيد الدخول',
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

          // Resend Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لم يصلك الكود؟ ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              TextButton(
                onPressed: (_resendSeconds == 0 && !_isResending) ? _resendCode : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _resendSeconds > 0
                      ? 'إعادة الإرسال بعد ($_resendSeconds ثانية)'
                      : 'إعادة إرسال عبر الواتساب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _resendSeconds == 0
                        ? const Color(0xFF25D366)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Open WhatsApp Directly Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openWhatsAppDirectly,
              icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF25D366)),
              label: const Text(
                'فتح الواتساب لاستلام/تأكيد الكود',
                style: TextStyle(
                  color: Color(0xFF25D366),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
