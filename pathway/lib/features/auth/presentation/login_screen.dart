import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/app_scaffold.dart';
import 'signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// Import validators
import 'package:pathway/core/utils/validators.dart';

// Change to StatefulWidget to manage form state and text input
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLoginForm() async {
  if (_formKey.currentState!.validate()) {
    print('Attempting Login for: ${_emailController.text}');

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PathwayNavShell(),
        ),
      );
    } on AuthException catch (e) {
      print('Login failed: ${e.message}');
    } catch (e) {
      print('Login failed: $e');
    }
  }
}


  // Function to navigate to the Signup screen
  void _navigateToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        // This links to the SignupScreen you just built!
        builder: (context) => const SignupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SingleChildScrollView( // Use SingleChildScrollView to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Application Title/Logo
                Text(
                  'Welcome Back!',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.isValidEmail, // Use your centralized validator
                ),
                const SizedBox(height: 12),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: AppValidators.isValidPassword, // Use your centralized validator
                ),
                const SizedBox(height: 30),

                // Log In Button
                ElevatedButton(
                  onPressed: _submitLoginForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Log In', style: TextStyle(fontSize: 18)),
                ),
                
                const SizedBox(height: 20),

                // FORGOT PASSWORD (Optional)
                TextButton(
                  onPressed: () {
                    print('Forgot Password link pressed');
                    // TODO: Implement navigation for Forgot Password flow
                  },
                  child: const Text('Forgot Password?'),
                ),

                const SizedBox(height: 40),
                
                // === SIGN UP LINK === (The solution to your problem)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _navigateToSignup, // Calls the navigation function
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}