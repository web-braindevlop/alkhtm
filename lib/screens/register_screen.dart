import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (result != null && mounted) {
        // Registration successful - now log in
        final loginResult = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (loginResult != null && mounted) {
          Navigator.of(context).pop(true); // Return true to indicate successful registration
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        // Registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Email may already be in use.'),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = screenWidth >= 800 ? 20.0 : 16.0;
    final buttonSpacing = screenWidth >= 800 ? 32.0 : 24.0;
    final titleSize = screenWidth >= 800 ? 32.0 : 28.0;
    final subtitleSize = screenWidth >= 800 ? 18.0 : 16.0;
    final fontSize = screenWidth >= 800 ? 18.0 : 16.0;
    final iconSize = screenWidth >= 800 ? 28.0 : 24.0;
    final borderRadius = screenWidth >= 800 ? 16.0 : 12.0;
    final buttonHeight = screenWidth >= 800 ? 64.0 : 56.0;
    final maxWidth = screenWidth >= 1200 ? 600.0 : (screenWidth >= 800 ? 550.0 : 500.0);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register',
          style: TextStyle(fontSize: screenWidth >= 800 ? 22 : 20),
        ),
        backgroundColor: const Color(0xFF79B2D5),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.isTablet(context) || ResponsiveUtils.isDesktop(context) ? maxWidth : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Form(
                key: _formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenWidth >= 800 ? 24 : 20),
                
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Please fill in the details to create your account',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: const Color(0xFF1a1a1a),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: buttonSpacing),
                
                // First Name
                TextFormField(
                  controller: _firstNameController,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.person, size: iconSize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'First name is required';
                    return null;
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'Last Name *',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.person_outline, size: iconSize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Last name is required';
                    return null;
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.email, size: iconSize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: fontSize),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone (optional)',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.phone, size: iconSize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                ),
                
                SizedBox(height: spacing),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.lock, size: iconSize),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: iconSize),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password is required';
                    if (value!.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    labelStyle: TextStyle(fontSize: fontSize),
                    prefixIcon: Icon(Icons.lock_outline, size: iconSize),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, size: iconSize),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please confirm password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                
                SizedBox(height: buttonSpacing),
                
                // Register Button
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF79B2D5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
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
                        : Text(
                            'Register',
                            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                SizedBox(height: buttonSpacing),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: const Color(0xFF79B2D5),
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
