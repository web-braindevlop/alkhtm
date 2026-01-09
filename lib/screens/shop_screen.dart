import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/woocommerce_service.dart';
import '../widgets/content_widgets.dart';
import '../utils/responsive_utils.dart';
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
  String _currentSearchQuery = ''; // Track current search query
  bool _isSearchMode = false; // Track if we're in search mode

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSearchMode = false; // Not in search mode
      _currentSearchQuery = ''; // Clear search query
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
        title: _isSearchMode 
            ? Text('Search: $_currentSearchQuery')
            : const Text('Shop'),
        actions: [
          if (_isSearchMode)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: _loadProducts, // Load all products again
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
      onRefresh: _handleRefresh,
      child: GridView.builder(
        padding: ResponsiveUtils.getScreenPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(
            context,
            mobile: 2,
            tablet: 3,
            desktop: 4,
          ),
          childAspectRatio: ResponsiveUtils.getCardAspectRatio(context),
          crossAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
          mainAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
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

  // Show search dialog
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        return AlertDialog(
          title: const Text('Search Products'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter product name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              searchQuery = value;
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.of(context).pop();
                _performSearch(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (searchQuery.isNotEmpty) {
                  Navigator.of(context).pop();
                  _performSearch(searchQuery);
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  // Perform search
  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSearchMode = true; // Entering search mode
      _currentSearchQuery = query; // Save the search query
    });

    try {
      print('🔍 [SEARCH] Searching for: "$query"');
      final results = await _wooService.searchProducts(query);
      print('✅ [SEARCH] Found ${results.length} results for "$query"');
      
      setState(() {
        _products = results;
        _isLoading = false;
      });
      
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No products found for "$query"')),
        );
      }
    } catch (e) {
      print('❌ [SEARCH] Error: $e');
      setState(() {
        _errorMessage = 'Search error: $e';
        _isLoading = false;
      });
    }
  }

  // Handle refresh - respects search mode
  Future<void> _handleRefresh() async {
    if (_isSearchMode && _currentSearchQuery.isNotEmpty) {
      // Re-run the search
      await _performSearch(_currentSearchQuery);
    } else {
      // Load all products
      await _loadProducts();
    }
  }
}
