import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/woocommerce_service.dart';
import '../widgets/content_widgets.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const ShopScreen({super.key, this.scaffoldKey});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final WooCommerceService _wooService = WooCommerceService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _wooService.getProducts(perPage: 20);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: Theme.of(context).primaryColor,
          size: 50.0,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Products Available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ProductCard(
            name: product.name,
            price: 'د.إ ${product.price}',
            originalPrice: product.onSale ? 'د.إ ${product.regularPrice}' : null,
            imageUrl: product.images.isNotEmpty ? product.images.first.src : null,
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
    );
  }
}
