import 'package:flutter/material.dart';
import '../services/woocommerce_service.dart';
import '../widgets/content_widgets.dart';
import 'product_detail_screen.dart';
import 'main_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final WooCommerceService _service = WooCommerceService();
  List<WooProduct> _products = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    final products = await _service.getProductsByCategory(
      widget.categoryId,
      page: _currentPage,
      perPage: 20,
    );

    setState(() {
      _products.addAll(products);
      _hasMore = products.length >= 20;
      _currentPage++;
      _isLoading = false;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _products.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: _products.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? const Center(child: Text('No products found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _products.length) {
                        if (_isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else {
                          _loadProducts();
                          return const SizedBox.shrink();
                        }
                      }

                      final product = _products[index];
                      return ProductCard(
                        name: product.name,
                        price: 'د.إ ${product.price}',
                        originalPrice: product.onSale
                            ? 'د.إ ${product.regularPrice}'
                            : null,
                        imageUrl: product.images.isNotEmpty
                            ? product.images.first.src
                            : null,
                        onSale: product.onSale,
                        rating: product.averageRating,
                        ratingCount: product.ratingCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: product.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
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
              _buildNavItem(context, Icons.home_outlined, 'Home', 0),
              _buildNavItem(context, Icons.shopping_bag_outlined, 'Shop', 1),
              _buildNavItem(context, Icons.shopping_cart_outlined, 'Cart', 2),
              _buildNavItem(context, Icons.favorite_border, 'Wishlist', 3),
              _buildNavItem(context, Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigate back to main screen with selected tab
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainScreen(initialTab: index),
            ),
            (route) => false,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
