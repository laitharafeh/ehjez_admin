import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  /// Returns true if [phone] belongs to a court owner OR has a pending staff invite.
  static Future<bool> courtExistsForPhone(String phone) async {
    final result = await _client
        .rpc('phone_has_court_access', params: {'p_phone': phone});
    return result == true;
  }

  /// Sends an OTP SMS to [phone].
  static Future<void> signInWithOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  /// Verifies the OTP [token] for [phone] and returns the auth response.
  static Future<AuthResponse> verifyOtp(String phone, String token) async {
    return _client.auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
  }

  /// Signs the current user out.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
