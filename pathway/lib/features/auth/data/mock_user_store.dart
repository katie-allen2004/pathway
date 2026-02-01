//Aiden creates a mock "user database"
class MockUserStore {
  // pretend database (email -> user data)
  static final Map<String, Map<String, String>> _usersByEmail = {};

  static bool emailExists(String email) {
    return _usersByEmail.containsKey(email.toLowerCase());
  }

  static void createUser({
    required String email,
    required String password,
    String? name,
  }) {
    _usersByEmail[email.toLowerCase()] = {
      'email': email,
      'password': password, // (demo only; real apps never store raw passwords)
      'name': name ?? '',
    };
  }
}