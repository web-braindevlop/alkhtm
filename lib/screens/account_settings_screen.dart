import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import 'login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isDeleting = false;

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Account?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'When you delete your account:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeleteInfoItem('Your profile and personal data will be permanently deleted'),
              _buildDeleteInfoItem('All your order history will be removed'),
              _buildDeleteInfoItem('You will not be able to recover this account'),
              _buildDeleteInfoItem('This action cannot be reversed'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Are you sure you want to proceed?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Widget _buildDeleteInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.red[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      final success = await _authService.deleteAccount();

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been permanently deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again or contact support.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = screenWidth >= 800 ? 22.0 : 20.0;
    final subtitleSize = screenWidth >= 800 ? 16.0 : 14.0;
    final padding = screenWidth >= 1200 ? 32.0 : (screenWidth >= 800 ? 24.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: TextStyle(fontSize: titleSize),
        ),
        backgroundColor: const Color(0xFF79B2D5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information section
            Card(
              elevation: 0,
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue[100]!),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Manage your account settings and preferences',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: padding * 1.5),

            // Danger Zone Section
            Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Irreversible actions that affect your account',
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 20),

            // Delete Account Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red[200]!, width: 1.5),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_forever,
                            color: Colors.red[700],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Permanently delete your account and all data',
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What happens when you delete your account:',
                            style: TextStyle(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDeleteInfoItem('All your personal information will be removed'),
                          _buildDeleteInfoItem('Your order history will be deleted'),
                          _buildDeleteInfoItem('You will lose access to your account immediately'),
                          _buildDeleteInfoItem('This action cannot be undone'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : _showDeleteAccountDialog,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_forever),
                        label: Text(
                          _isDeleting ? 'Deleting Account...' : 'Delete My Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Help text
            Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you\'re having issues with your account or want to provide feedback, please contact our support team before deleting your account.',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
