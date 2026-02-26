import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('REGISTER CALLED email=$email');

      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: name == null ? null : {'display_name': name},
      );

      final userId = res.user?.id;
      debugPrint('SIGNUP user id: $userId');

      if (userId == null) {
        return const RegisterResult(
          success: false,
          message: 'Signup did not return a user.',
        );
      }

      if (res.session == null) {
        return const RegisterResult(
          success: true,
          message: 'Check your email to confirm your account.',
        );
      }

      await Supabase.instance.client.schema('pathway').from('profiles').insert({
        'user_id': userId,
        'display_name': name,
      });

      await Supabase.instance.client.schema('pathway').from('users').insert({
        'external_id': userId,
        'email': email,
      });

      debugPrint('Data successfully synced for $userId');
      return const RegisterResult(success: true, message: 'Account created!');
    } on AuthException catch (e) {
      debugPrint('SIGNUP AuthException: ${e.message}');
      return RegisterResult(success: false, message: e.message);
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');
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
