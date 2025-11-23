import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dynamic_home_screen.dart';
import 'shop_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'dart:async';

// Export MainScreenState for access from other screens
export 'main_screen.dart' show MainScreenState;

class MainScreen extends StatefulWidget {
  final int initialTab;
  
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _shopScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _cartScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _wishlistScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _profileScaffoldKey = GlobalKey<ScaffoldState>();
  int _cartItemCount = 0;
  StreamController<int>? _cartCountController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _cartCountController = StreamController<int>.broadcast();
    _loadCartCount();
    // Update cart count every 2 seconds when app is active
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadCartCount();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cartCountController?.close();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart') ?? '[]';
    final List<dynamic> cart = json.decode(cartJson);
    final count = cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
    if (mounted && count != _cartItemCount) {
      setState(() {
        _cartItemCount = count;
      });
      _cartCountController?.add(count);
    }
  }

  void goToCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart') ?? '[]';
    final List<dynamic> cartItems = json.decode(cartJson);
    
    if (cartItems.isEmpty) return;
    
    final total = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0) * (item['quantity'] as int? ?? 0),
    );
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            cartItems: cartItems.cast<Map<String, dynamic>>(),
            total: total,
          ),
        ),
      ).then((_) {
        _loadCartCount();
        _cartKey.currentState?.refreshCart();
      });
    }
  }

  void _closeAllDrawers() {
    // Close drawer on home screen if open
    if (_homeScaffoldKey.currentState?.isDrawerOpen ?? false) {
      _homeScaffoldKey.currentState?.closeDrawer();
    }
    // Close drawer on shop screen if open
    if (_shopScaffoldKey.currentState?.isDrawerOpen ?? false) {
      _shopScaffoldKey.currentState?.closeDrawer();
    }
    // Close drawer on cart screen if open
    if (_cartScaffoldKey.currentState?.isDrawerOpen ?? false) {
      _cartScaffoldKey.currentState?.closeDrawer();
    }
    // Close drawer on wishlist screen if open
    if (_wishlistScaffoldKey.currentState?.isDrawerOpen ?? false) {
      _wishlistScaffoldKey.currentState?.closeDrawer();
    }
    // Close drawer on profile screen if open
    if (_profileScaffoldKey.currentState?.isDrawerOpen ?? false) {
      _profileScaffoldKey.currentState?.closeDrawer();
    }
  }

  void switchToTab(int index) {
    // Close any open drawer before switching tabs
    _closeAllDrawers();
    
    setState(() {
      _currentIndex = index;
    });
    // Refresh cart when switching to cart tab
    if (index == 2) {
      // Small delay to ensure cart is built
      Future.delayed(const Duration(milliseconds: 100), () {
        _cartKey.currentState?.refreshCart();
        _loadCartCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DynamicHomeScreen(scaffoldKey: _homeScaffoldKey),
          ShopScreen(scaffoldKey: _shopScaffoldKey),
          CartScreen(key: _cartKey, scaffoldKey: _cartScaffoldKey),
          WishlistScreen(scaffoldKey: _wishlistScaffoldKey),
          ProfileScreen(scaffoldKey: _profileScaffoldKey),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF79B2D5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag,
                    label: 'Shop',
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart,
                    label: 'Cart',
                    index: 2,
                    badge: _cartItemCount,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    label: 'Wishlist',
                    index: 3,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    index: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int badge = 0,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? Colors.white : Colors.white70;

    return GestureDetector(
      onTap: () {
        // Close any open drawer before switching
        _closeAllDrawers();
        
        setState(() {
          _currentIndex = index;
        });
        if (index == 2) {
          _loadCartCount();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
