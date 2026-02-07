import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterResult {
  final bool success;
  final String message;
  const RegisterResult({required this.success, required this.message});
}

class AuthService {
  Future<RegisterResult> register({
    String? name,
    required String email,
    required String password,
  }) async {
    try {
      print('REGISTER CALLED email=$email');

      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: name == null ? null : {'name': name},
      );

      print('SIGNUP user=${res.user?.id} session=${res.session != null}');

      // Email confirmation flow: this can still be a successful signup.
      if (res.user == null) {
        return const RegisterResult(
          success: true,
          message: 'Check your email to confirm your account.',
        );
      }

      return const RegisterResult(success: true, message: 'Account created!');
    } on AuthException catch (e) {
      print('SIGNUP AuthException: ${e.message}');
      return RegisterResult(success: false, message: e.message);
    } catch (e) {
      print('SIGNUP ERROR: $e');
      return RegisterResult(success: false, message: 'Signup failed: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }
}
