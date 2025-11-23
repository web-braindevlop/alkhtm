import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const ProfileScreen({super.key, this.scaffoldKey});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final userData = await _authService.fetchUserInfo();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _userData = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    setState(() {
      _isLoggedIn = false;
      _userData = null;
    });
    if (mounted) {
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
    return Scaffold(
      key: widget.scaffoldKey,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF79B2D5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isLoggedIn && _userData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userData: _userData!),
                  ),
                ).then((updated) {
                  if (updated == true) {
                    _checkLoginStatus();
                  }
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      drawer: AppDrawer(
        onLogout: () {
          setState(() {
            _isLoggedIn = false;
            _userData = null;
          });
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isLoggedIn && _userData != null
              ? _buildProfileContent()
              : _buildLoginPrompt(),
    );
  }

  Widget _buildProfileContent() {
    final firstName = _userData!['first_name'] ?? '';
    final lastName = _userData!['last_name'] ?? '';
    final email = _userData!['email'] ?? '';
    final phone = _userData!['billing']?['phone'] ?? '';
    final company = _userData!['billing']?['company'] ?? '';

    return RefreshIndicator(
      onRefresh: _checkLoginStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header with Gradient
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF79B2D5), Color(0xFF5A9BC7)],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Profile Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        (firstName.isNotEmpty ? firstName[0] : 'U').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF79B2D5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Action Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildActionCard(
                    icon: Icons.shopping_bag,
                    title: 'My Orders',
                    subtitle: 'View your order history',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Personal Information',
                    items: [
                      {'label': 'Name', 'value': '$firstName $lastName'},
                      {'label': 'Email', 'value': email},
                      if (phone.isNotEmpty) {'label': 'Phone', 'value': phone},
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Billing Address',
                    items: <Map<String, String>>[
                      if (company.isNotEmpty)
                        {'label': 'Company', 'value': company},
                      if ((_userData!['billing']?['address_1'] ?? '').toString().isNotEmpty)
                        {'label': 'Address', 'value': (_userData!['billing']?['address_1'] ?? '').toString()},
                      if ((_userData!['billing']?['address_2'] ?? '').toString().isNotEmpty)
                        {'label': 'Address 2', 'value': (_userData!['billing']?['address_2'] ?? '').toString()},
                      if ((_userData!['billing']?['city'] ?? '').toString().isNotEmpty)
                        {'label': 'City', 'value': (_userData!['billing']?['city'] ?? '').toString()},
                      if ((_userData!['billing']?['state'] ?? '').toString().isNotEmpty)
                        {'label': 'State', 'value': (_userData!['billing']?['state'] ?? '').toString()},
                      if ((_userData!['billing']?['postcode'] ?? '').toString().isNotEmpty)
                        {'label': 'Postcode', 'value': (_userData!['billing']?['postcode'] ?? '').toString()},
                      if ((_userData!['billing']?['country'] ?? '').toString().isNotEmpty)
                        {'label': 'Country', 'value': (_userData!['billing']?['country'] ?? '').toString()},
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Map<String, String>> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF79B2D5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF79B2D5), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF79B2D5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 80,
                color: Color(0xFF79B2D5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Al Khatm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Login to view your profile, orders, and manage your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
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
                icon: const Icon(Icons.login),
                label: const Text(
                  'Login / Register',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF79B2D5),
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
    );
  }
}
