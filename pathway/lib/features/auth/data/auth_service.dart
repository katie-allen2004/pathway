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
        email: email,
        password: password,
        data: name == null ? null : {'name': name},
      );

      print('SIGNUP user id: ${res.user?.id}');

      if (res.user == null) {
        return const RegisterResult(
          success: false,
          message: 'Signup did not return a user. Check email confirmation settings.',
        );
      }

      return const RegisterResult(success: true, message: 'Account created!');
    } on AuthException catch (e) {
      print('SIGNUP AuthException: ${e.message}');
      return RegisterResult(success: false, message: e.message);
    } catch (e) {
      print('SIGNUP ERROR: $e');
      return const RegisterResult(success: false, message: 'Signup failed.');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
