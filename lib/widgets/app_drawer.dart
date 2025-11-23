import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/page_detail_screen.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback? onLogout;

  const AppDrawer({super.key, this.onLogout});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isPoliciesExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn && mounted) {
      final userData = await _authService.getUserData();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _userData = userData;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userData = null;
      });
    }
    if (mounted) {
      Navigator.pop(context);
      widget.onLogout?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Modern Gradient Header
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF79B2D5), Color(0xFF5A9BC7)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CachedNetworkImage(
                        imageUrl: 'https://alkhatm.com/wp-content/uploads/2024/05/Untitled_design__1_-removebg-preview.png',
                        height: 50,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SizedBox(
                          height: 50,
                          width: 60,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF79B2D5),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.store,
                          size: 50,
                          color: Color(0xFF79B2D5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Al Khatm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gents Tailoring LLC',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // User Profile Section
            if (_isLoggedIn && _userData != null) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF79B2D5), Color(0xFF5A9BC7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (_userData!['first_name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_userData!['first_name']} ${_userData!['last_name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userData!['email'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.verified_user,
                      color: Colors.green[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
              _buildModernTile(
                icon: Icons.shopping_bag_rounded,
                title: 'My Orders',
                subtitle: 'View order history',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 24, thickness: 1),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF79B2D5), Color(0xFF5A9BC7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF79B2D5).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      ).then((loggedIn) {
                        if (loggedIn == true) {
                          _checkLoginStatus();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Login / Register',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Access your orders and profile',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 24, thickness: 1),
            ],

            // Navigation Items
            _buildSimpleTile(
              icon: Icons.home_rounded,
              title: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _buildSimpleTile(
              icon: Icons.info_rounded,
              title: 'About Us',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PageDetailScreen(pageId: 805),
                  ),
                );
              },
            ),

            // Policies Expandable Section
            ExpansionTile(
              leading: const Icon(Icons.policy_rounded, color: Color(0xFF79B2D5)),
              title: const Text(
                'Policies',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: _isPoliciesExpanded,
              onExpansionChanged: (expanded) {
                if (mounted) {
                  setState(() {
                    _isPoliciesExpanded = expanded;
                  });
                }
              },
              children: [
                _buildSubTile(
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 976),
                      ),
                    );
                  },
                ),
                _buildSubTile(
                  title: 'Refund and Returns Policy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 12),
                      ),
                    );
                  },
                ),
                _buildSubTile(
                  title: 'Delivery Policy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 1197),
                      ),
                    );
                  },
                ),
                _buildSubTile(
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 3),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            // Logout Button at Bottom (for logged in users only)
            if (_isLoggedIn) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // App Version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF79B2D5)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSubTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
