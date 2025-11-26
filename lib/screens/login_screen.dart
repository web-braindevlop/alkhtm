import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result != null && mounted) {
        // Login successful
        Navigator.of(context).pop(true); // Return true to indicate successful login
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${result['first_name']}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final success = await _authService.requestPasswordReset(email);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'If the email exists, a password reset link will be sent'
                          : 'Failed to send reset link. Please try again.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF79B2D5),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth >= 800 ? 120.0 : 100.0;
    final spacing = screenWidth >= 800 ? 48.0 : 40.0;
    final buttonHeight = screenWidth >= 800 ? 64.0 : 56.0;
    final fontSize = screenWidth >= 800 ? 18.0 : 16.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(fontSize: screenWidth >= 800 ? 22 : 20),
        ),
        backgroundColor: const Color(0xFF79B2D5),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth >= 1200 ? 600 : (screenWidth >= 800 ? 550 : double.infinity),
            ),
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Form(
                key: _formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: spacing),
                
                // Logo or Icon
                Icon(
                  Icons.account_circle,
                  size: iconSize,
                  color: const Color(0xFF79B2D5),
                ),
                
                SizedBox(height: spacing),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.email, size: screenWidth >= 800 ? 28 : 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth >= 800 ? 16 : 12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth >= 800 ? 16 : 12),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                
                SizedBox(height: screenWidth >= 800 ? 20 : 16),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.lock, size: screenWidth >= 800 ? 28 : 24),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      iconSize: screenWidth >= 800 ? 28 : 24,
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth >= 800 ? 16 : 12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth >= 800 ? 16 : 12),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password is required';
                    return null;
                  },
                ),
                
                SizedBox(height: screenWidth >= 800 ? 32 : 24),
                
                // Login Button
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF79B2D5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth >= 800 ? 16 : 12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: screenWidth >= 800 ? 28 : 24,
                            height: screenWidth >= 800 ? 28 : 24,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Forgot Password
                Center(
                  child: TextButton(
                    onPressed: () {
                      _showForgotPasswordDialog();
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF79B2D5),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        ).then((registered) {
                          if (registered == true) {
                            // User registered, go back
                            Navigator.of(context).pop(true);
                          }
                        });
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Color(0xFF79B2D5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    ),
    );
  }
}
