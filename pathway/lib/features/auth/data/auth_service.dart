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
        data: name == null ? null : {'display_name': name},
      );

      final userId = res.user?.id;
      print('SIGNUP user id: $userId');

      if (userId == null) {
        return const RegisterResult(
          success: false,
          message: 'Signup did not return a user.',
        );
      }

      await Supabase.instance.client
          .schema('pathway')
          .from('profiles')
          .insert({
            'user_id': userId,
            'display_name': name,
          });

      await Supabase.instance.client
          .schema('pathway')
          .from('users')
          .insert({

            'external_id': userId,  
            'email': email,          
          });

      print('Data successfully synced to profiles and users tables for $userId');

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