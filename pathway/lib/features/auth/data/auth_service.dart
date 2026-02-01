import 'mock_user_store.dart';

class RegisterResult {
  final bool success;
  final String message;
  const RegisterResult({required this.success, required this.message});
}

class AuthService {
  Future<RegisterResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (MockUserStore.emailExists(email)) {
      return const RegisterResult(
        success: false,
        message: 'That email is already registered.',
      );
    }

    MockUserStore.createUser(email: email, password: password, name: name);

    return const RegisterResult(
      success: true,
      message: 'Account created successfully!',
    );
  }
}
