import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  /// Returns true if the [phone] number is linked to a registered court.
  static Future<bool> courtExistsForPhone(String phone) async {
    final result = await _client
        .from('courts')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
    return result != null;
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

  /// Creates a user record on first login and links the user to their court
  /// via the court_managers table (upsert so repeat calls are safe).
  static Future<void> ensureUserRecord(String userId, String phone) async {
    await _client.from('users').upsert({'id': userId, 'phone': phone});
    // Populate court_managers for this user if not already present.
    // Uses a SECURITY DEFINER RPC so it can safely read auth.users.
    await _client.rpc('ensure_court_manager');
  }

  /// Signs the current user out.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
