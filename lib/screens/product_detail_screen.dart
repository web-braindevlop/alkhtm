import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';
import '../widgets/content_widgets.dart';
import '../utils/responsive_utils.dart';
import '../main.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final WooCommerceService _service = WooCommerceService();
  WooProduct? _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  List<WooProduct> _relatedProducts = [];
  bool _isLoadingRelated = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final product = await _service.getProduct(widget.productId);

    if (!mounted) return;
    setState(() {
      _product = product;
      _isLoading = false;
    });

    // Load related products
    if (product != null && product.relatedIds.isNotEmpty) {
      _loadRelatedProducts(product.relatedIds);
    }
  }

  Future<void> _loadRelatedProducts(List<int> relatedIds) async {
    if (!mounted) return;
    setState(() => _isLoadingRelated = true);

    try {
      final products = await _service.getProductsByIds(relatedIds);
      if (!mounted) return;
      setState(() {
        _relatedProducts = products;
        _isLoadingRelated = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share product
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found'))
              : _buildProductDetail(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildProductDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Images
          _buildImageGallery(),

          Padding(
            padding: ResponsiveUtils.getScreenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  _product!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Price
                Row(
                  children: [
                    Text(
                      'د.إ ${_product!.price}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _product!.onSale ? Colors.red : Colors.black,
                      ),
                    ),
                    if (_product!.onSale && _product!.regularPrice.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        'د.إ ${_product!.regularPrice}',
                        style: TextStyle(
                          fontSize: 18,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Stock Status
                Row(
                  children: [
                    Icon(
                      _product!.inStock ? Icons.check_circle : Icons.cancel,
                      color: _product!.inStock ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _product!.inStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: _product!.inStock ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Categories
                if (_product!.categories.isNotEmpty) ...[
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _product!.categories.map((cat) {
                      return Chip(
                        label: Text(cat.name),
                        backgroundColor: Colors.blue[50],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Short Description
                if (_product!.shortDescription.isNotEmpty) ...[
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HtmlWidget(
                    _product!.shortDescription,
                    textStyle: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tabbed Section: Description & Reviews
                _buildTabbedSection(),

                const SizedBox(height: 24),

                // Related Products Section
                if (_relatedProducts.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildRelatedProductsSection(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Description'),
              Tab(text: 'Reviews'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildDescriptionTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      child: _product!.description.isNotEmpty
          ? HtmlWidget(
              _product!.description,
              textStyle: const TextStyle(fontSize: 14, height: 1.5),
            )
          : const Center(
              child: Text('No description available'),
            ),
    );
  }

  Widget _buildReviewsTab() {
    return _ReviewsSection(productId: _product!.id);
  }

  Widget _buildImageGallery() {
    final images = _product!.images;
    if (images.isEmpty) {
      return Container(
        height: 400,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index].src,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 100),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }



  Widget _buildRelatedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingRelated)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _relatedProducts.length,
              itemBuilder: (context, index) {
                final product = _relatedProducts[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    name: product.name,
                    price: product.price,
                    originalPrice: product.onSale ? product.regularPrice : null,
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _product!.inStock
                  ? () async {
                      await _addToCart();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to cart!'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () {
                                // Pop current screen and switch to cart tab
                                Navigator.of(context).pop();
                                mainScreenKey.currentState?.switchToTab(2);
                              },
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _product!.inStock
                ? () async {
                    await _addToCart();
                    if (mounted) {
                      // Pop current screen and switch to checkout
                      Navigator.of(context).pop();
                      mainScreenKey.currentState?.switchToTab(2);
                      // Navigate to checkout after a small delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          mainScreenKey.currentState?.goToCheckout();
                        }
                      });
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buy Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart') ?? '[]';
    final List<dynamic> cart = json.decode(cartJson);

    // Check if product already exists in cart
    final existingIndex = cart.indexWhere((item) => item['id'] == _product!.id);

    if (existingIndex >= 0) {
      // Increment quantity
      cart[existingIndex]['quantity'] = (cart[existingIndex]['quantity'] as int) + 1;
    } else {
      // Add new item
      cart.add({
        'id': _product!.id,
        'name': _product!.name,
        'price': _product!.price,
        'image': _product!.images.isNotEmpty ? _product!.images.first.src : '',
        'quantity': 1,
      });
    }

    await prefs.setString('cart', json.encode(cart));
  }
}

/// Reviews Section Widget
class _ReviewsSection extends StatefulWidget {
  final int productId;

  const _ReviewsSection({required this.productId});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 0;
  int _ratingCount = 0;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadReviews();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final userData = await _authService.getUserData();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _userData = userData;
          // Pre-fill name and email for logged-in users
          if (userData != null) {
            _nameController.text = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
            _emailController.text = userData['email'] ?? '';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);

    try {
      final url = 'https://alkhatm.com/wp-api-bridge.php?action=product_reviews&id=${widget.productId}&per_page=20';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final reviewsData = data['data']['reviews'] as List;
          final productRating = data['data']['product_rating'];
          
          setState(() {
            _reviews = reviewsData.map((r) => Review.fromJson(r)).toList();
            _averageRating = double.tryParse(productRating['average'].toString()) ?? 0;
            _ratingCount = productRating['count'] ?? 0;
            _isLoadingReviews = false;
          });
        } else {
          setState(() => _isLoadingReviews = false);
        }
      } else {
        setState(() => _isLoadingReviews = false);
      }
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a rating'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('https://alkhatm.com/wp-api-bridge.php?action=submit_review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'product_id': widget.productId,
          'rating': _rating,
          'review': _reviewController.text,
          'name': _nameController.text,
          'email': _isLoggedIn && _userData != null 
              ? _userData!['email'] 
              : _emailController.text,
        }),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully! It will appear after admin approval.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Clear form
          _reviewController.clear();
          _nameController.clear();
          _emailController.clear();
          setState(() {
            _rating = 0;
          });
          // Reload reviews
          _loadReviews();
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to submit review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Rating Summary
          _buildRatingSummary(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Existing Reviews
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_reviews.isNotEmpty) ...[
            const Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._reviews.map((review) => _buildReviewCard(review)).toList(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to review this product!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],
          
          // Review Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            const SizedBox(height: 16),
            
            // Rating Stars
            const Text(
              'Your Rating *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            
            // Review Text
            const Text(
              'Your Review *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your review';
                }
                if (value.trim().length < 10) {
                  return 'Review must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Name Field
            const Text(
              'Your Name *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Email Field - Only show for non-logged-in users
            if (!_isLoggedIn) ...[
              const Text(
                'Your Email *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ],
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRating(
                          rating: _averageRating,
                          ratingCount: 0,
                          size: 20,
                          showCount: false,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_ratingCount reviews',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    review.reviewerName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.verified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StarRating(
                            rating: review.rating.toDouble(),
                            ratingCount: 0,
                            size: 14,
                            showCount: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.review,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? "month" : "months"} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? "year" : "years"} ago';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

/// Review Model
class Review {
  final int id;
  final int productId;
  final String reviewerName;
  final String reviewerEmail;
  final String review;
  final int rating;
  final String date;
  final bool verified;

  Review({
    required this.id,
    required this.productId,
    required this.reviewerName,
    required this.reviewerEmail,
    required this.review,
    required this.rating,
    required this.date,
    required this.verified,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      reviewerName: json['reviewer_name']?.toString() ?? '',
      reviewerEmail: json['reviewer_email']?.toString() ?? '',
      review: json['review']?.toString() ?? '',
      rating: int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      verified: json['verified'] == true || json['verified'] == 'true',
    );
  }
}
