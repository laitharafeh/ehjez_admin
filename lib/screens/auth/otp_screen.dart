import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  Future<void> _verify() async {
    final s = S.of(context);
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = s.pleaseEnterCode);
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      final res = await AuthService.verifyOtp(widget.phoneNumber, code);
      if (!mounted) return;
      if (res.session != null) {
        await AuthService.ensureUserRecord(
          res.session!.user.id,
          widget.phoneNumber,
        );
        if (!mounted) return;
        context.go('/');
      } else {
        setState(() => _error = S.of(context).invalidCode);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = S.of(context).invalidCode);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await AuthService.signInWithOtp(widget.phoneNumber);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).codeResent)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = S.of(context).resendFailed);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ehjez',
                  style: GoogleFonts.grandstander(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: ehjezGreen,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.adminPortal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.verifyYourNumber,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.codeSentTo(widget.phoneNumber),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        onSubmitted: (_) => _verify(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '······',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade300,
                            letterSpacing: 8,
                            fontSize: 22,
                          ),
                          errorText: _error,
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ehjezGreen,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ehjezGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                ehjezGreen.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  s.verify,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              s.changeNumber,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _isResending ? null : _resend,
                            child: Text(
                              _isResending ? s.sending : s.resendCode,
                              style: TextStyle(
                                color: ehjezGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
