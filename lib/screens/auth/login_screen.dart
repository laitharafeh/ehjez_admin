import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;
  bool _isSubmitting = false;

  bool _isValidJordanianNumber(String number) {
    return RegExp(r'^(?:962|0)7[789]\d{7}$').hasMatch(number);
  }

  String _normalizePhone(String number) {
    if (number.startsWith('0')) return number.replaceFirst('0', '962');
    if (number.startsWith('7')) return '962$number';
    return number.trim();
  }

  Future<void> _submit() async {
    final raw = _phoneController.text.trim();
    if (!_isValidJordanianNumber(raw)) {
      setState(() => _phoneError = 'Enter a valid Jordanian mobile number.');
      return;
    }

    final phone = _normalizePhone(raw);
    setState(() {
      _isSubmitting = true;
      _phoneError = null;
    });

    try {
      final exists = await AuthService.courtExistsForPhone(phone);
      if (!mounted) return;
      if (!exists) {
        setState(() =>
            _phoneError = 'This number is not linked to any court account.');
        return;
      }
      await AuthService.signInWithOtp(phone);
      if (!mounted) return;
      context.push('/otp', extra: phone);
    } catch (_) {
      if (!mounted) return;
      setState(() => _phoneError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                // ── Logo ──────────────────────────────────────────────────
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
                  'Admin Portal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Card ──────────────────────────────────────────────────
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
                      const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the phone number linked to your court',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phone field
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_phoneError != null) {
                            setState(() => _phoneError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: '07X XXX XXXX',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(
                            Icons.phone_iphone_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          errorText: _phoneError,
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

                      // Continue button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
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
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
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
