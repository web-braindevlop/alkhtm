import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../services/wordpress_service.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import '../models/wordpress_models.dart';
import '../widgets/content_widgets.dart';
import '../widgets/app_drawer.dart';
import '../config/api_config.dart';
import 'page_detail_screen.dart';
import 'product_detail_screen.dart';
import 'category_products_screen.dart';
import 'featured_products_screen.dart';
import 'sale_products_screen.dart';
import 'notification_settings_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class DynamicHomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const DynamicHomeScreen({super.key, this.scaffoldKey});

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  GlobalKey<ScaffoldState>? _scaffoldKey;
  final WordPressService _wpService = WordPressService();
  final WooCommerceService _wooService = WooCommerceService();

  Post? _homepage;
  SiteInfo? _siteInfo;
  List<dynamic> _categories = [];
  List<dynamic> _featuredProducts = [];
  List<dynamic> _saleProducts = [];
  bool _isLoading = true;
  
  // Product showcase autoplay
  late PageController _showcasePageController;
  Timer? _showcaseTimer;
  int _currentShowcasePage = 0;
  String _errorMessage = '';
  
  // Footer slider
  late PageController _footerPageController;
  int _currentFooterPage = 0;
  
  // Sidebar menu state
  bool _isPoliciesExpanded = false;
  
  // User authentication
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  
  // Social media links
  Map<String, String> _socialLinks = {};
  
  // Contact info
  String _contactPhone = '';
  String _contactEmail = '';
  String _contactAddress = '';

  @override
  void initState() {
    super.initState();
    _showcasePageController = PageController(viewportFraction: 0.45);
    _footerPageController = PageController();
    _startShowcaseAutoplay();
    _loadHomePageContent();
    _checkLoginStatus();
  }
  
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final userData = await _authService.getUserData();
      setState(() {
        _isLoggedIn = true;
        _userData = userData;
      });
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
        ),
      );
    }
  }

  @override
  void dispose() {
    _showcaseTimer?.cancel();
    _showcasePageController.dispose();
    _footerPageController.dispose();
    super.dispose();
  }

  void _startShowcaseAutoplay() {
    _showcaseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_showcasePageController.hasClients) {
        _currentShowcasePage = (_currentShowcasePage + 1) % 9; // 9 images total
        _showcasePageController.animateToPage(
          _currentShowcasePage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _extractPhone(String content) {
    final phoneRegex = RegExp(r'\+971\s*\d{2}\s*\d{3}\s*\d{4}');
    final match = phoneRegex.firstMatch(content);
    return match?.group(0)?.replaceAll(' ', '') ?? '+971566810269';
  }

  String _extractEmail(String content) {
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final match = emailRegex.firstMatch(content);
    return match?.group(0) ?? 'info@alkhatm.com';
  }

  String _extractAddress(String content) {
    final addressMatch = RegExp(r'Al Khatm[^<]*?UAE', caseSensitive: false).firstMatch(content);
    return addressMatch?.group(0) ?? 'Al Khatm Gents Tailoring LLC, Exhibition showroom no: 47, Ajman industrial-1, UAE';
  }

  Map<String, String> _extractSocialLinks(String content) {
    final socialLinks = <String, String>{};
    
    // Extract WhatsApp
    final whatsappMatch = RegExp(r'wa\.me/(\d+)').firstMatch(content);
    if (whatsappMatch != null) {
      socialLinks['whatsapp'] = 'https://wa.me/${whatsappMatch.group(1)}';
    }
    
    // Extract Facebook
    final facebookMatch = RegExp(r'facebook\.com/[^\s<>]+').firstMatch(content);
    if (facebookMatch != null) {
      socialLinks['facebook'] = 'https://${facebookMatch.group(0)}';
    }
    
    // Extract Instagram
    final instagramMatch = RegExp(r'instagram\.com/[^\s<>]+').firstMatch(content);
    if (instagramMatch != null) {
      socialLinks['instagram'] = 'https://${instagramMatch.group(0)}';
    }
    
    // Extract Snapchat
    final snapchatMatch = RegExp(r'snapchat\.com/add/[^\s<>?]+').firstMatch(content);
    if (snapchatMatch != null) {
      socialLinks['snapchat'] = 'https://${snapchatMatch.group(0)}';
    }
    
    return socialLinks;
  }

  Future<void> _loadHomePageContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load data sequentially with proper typing
      final siteInfoResponse = await _wpService.getSiteInfo();
      final homepageResponse = await _wpService.getPage(214); // Get homepage by ID
      final categories = await _wooService.getCategories();
      
      final featuredProducts = await _wooService.getFeaturedProducts(perPage: 8);
      final saleProducts = await _wooService.getSaleProducts(perPage: 8);
      
      // Load contact page to extract social links and contact info
      try {
        final contactPageResponse = await _wpService.getPage(807);
        if (contactPageResponse.isSuccess && contactPageResponse.data != null) {
          final pageHtml = await http.get(Uri.parse(contactPageResponse.data!.url));
          if (pageHtml.statusCode == 200) {
            final htmlContent = pageHtml.body;
            _socialLinks = _extractSocialLinks(htmlContent);
            _contactPhone = _extractPhone(htmlContent);
            _contactEmail = _extractEmail(htmlContent);
            _contactAddress = _extractAddress(htmlContent);
          }
        }
      } catch (e) {
        // Use defaults if extraction fails
        _socialLinks = {};
        _contactPhone = '+971566810269';
        _contactEmail = 'info@alkhatm.com';
        _contactAddress = 'Al Khatm Gents Tailoring LLC, Exhibition showroom no: 47, Ajman industrial-1, UAE';
      }

      setState(() {
        // Site info
        if (siteInfoResponse.isSuccess) {
          _siteInfo = siteInfoResponse.data;
        }

        // Homepage content - Load page ID 214 directly
        if (homepageResponse.isSuccess && homepageResponse.data != null) {
          _homepage = homepageResponse.data;
        }

        // Categories
        _categories = categories;

        // Featured products
        _featuredProducts = featuredProducts;

        // Sale products
        _saleProducts = saleProducts;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading content: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 70,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final leftLogoHeight = maxWidth < 400 ? 55.0 : 75.0;
            final rightLogoHeight = maxWidth < 400 ? 45.0 : 60.0;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: CachedNetworkImage(
                    imageUrl: 'https://alkhatm.com/wp-content/uploads/2024/05/Untitled_design__1_-removebg-preview.png',
                    height: leftLogoHeight,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => SizedBox(
                      height: leftLogoHeight,
                      width: 60,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 0),
                Flexible(
                  child: CachedNetworkImage(
                    imageUrl: 'https://alkhatm.com/wp-content/uploads/2024/07/AL_KHATM_LOGO-removebg-preview-1.png',
                    height: rightLogoHeight,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => SizedBox(
                      height: rightLogoHeight,
                      width: 80,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        onLogout: () {
          setState(() {
            _isLoggedIn = false;
            _userData = null;
          });
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomePageContent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF79B2D5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://alkhatm.com/wp-content/uploads/2024/05/Untitled_design__1_-removebg-preview.png',
                  height: 40,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 40,
                    width: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                CachedNetworkImage(
                  imageUrl: 'https://alkhatm.com/wp-content/uploads/2024/07/AL_KHATM_LOGO-removebg-preview-1.png',
                  height: 40,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 40,
                    width: 80,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.store, size: 30, color: Color(0xFF1976D2)),
                  ),
                ),
              ],
            ),
          ),
          
          // User Profile Section
          if (_isLoggedIn && _userData != null) ...[
            Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF79B2D5),
                        child: Text(
                          (_userData!['first_name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                            ),
                            Text(
                              _userData!['email'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Color(0xFF79B2D5)),
              title: const Text('My Orders'),
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
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const Divider(),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFF79B2D5)),
              title: const Text('Login / Register'),
              subtitle: const Text('Access your orders and profile'),
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
            ),
            const Divider(),
          ],
          
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 300));
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PageDetailScreen(pageId: 805),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(_isPoliciesExpanded ? Icons.expand_less : Icons.expand_more),
            title: const Text('Policies'),
            trailing: Icon(
              _isPoliciesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
            ),
            onTap: () {
              setState(() {
                _isPoliciesExpanded = !_isPoliciesExpanded;
              });
            },
          ),
          if (_isPoliciesExpanded) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: ListTile(
                leading: const Icon(Icons.circle, size: 8),
                title: const Text('Terms & Conditions'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 976),
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: ListTile(
                leading: const Icon(Icons.circle, size: 8),
                title: const Text('Refund and Returns Policy'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 12),
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: ListTile(
                leading: const Icon(Icons.circle, size: 8),
                title: const Text('Delivery Policy'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 985),
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: ListTile(
                leading: const Icon(Icons.circle, size: 8),
                title: const Text('Privacy Policy'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDetailScreen(pageId: 996),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text('Contact Us'),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 300));
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PageDetailScreen(pageId: 807),
                  ),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
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
              onPressed: _loadHomePageContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Hero Section - from website's "OFFER ZONE"
        _buildHeroSection(),

        // Country Flags Section
        _buildCountryFlagsSection(),

        // Main Categories Section
        if (_categories.isNotEmpty) _buildCategoriesSection(),
        
        // Featured Products
        if (_featuredProducts.isNotEmpty) _buildFeaturedProductsSection(),

        // Sale Items
        if (_saleProducts.isNotEmpty) _buildSaleSection(),

        // Features Section (after Sale Items)
        _buildFeaturesSection(),

        // About Us Section
        _buildAboutUsSection(),

        // Product Showcase Section
        _buildProductShowcaseSection(),

        // Google Maps Section
        _buildGoogleMapsSection(),

        // Footer Section
        _buildFooterSection(),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroSection() {
    // Default values
    String heroTitle = 'OFFER ZONE';
    String heroSubtitle = 'AL KHATM GROUP OF COMPANIES, established in the year 2005, is a ubiquitous brand name in fashion, including traditional gents fashion, kids fashion, uniforms, accessories, perfumes and footwear.';
    String? heroImageUrl;
    Color heroBackgroundColor = const Color(0xFF79B2D5); // Correct blue #79b2d5
    
    // Get image from homepage
    if (_homepage != null) {
      // Try featured image first
      if (_homepage!.featuredImage != null) {
        heroImageUrl = _homepage!.featuredImage!.large;
      } 
      // Then try first content image
      else if (_homepage!.firstContentImage != null && _homepage!.firstContentImage!.isNotEmpty) {
        heroImageUrl = _homepage!.firstContentImage;
      }
      
      // Extract title and subtitle from content
      final content = _homepage!.content;
      
      // Extract OFFER ZONE title
      final h2Match = RegExp(r'<h2>(.*?)<').firstMatch(content);
      if (h2Match != null) {
        heroTitle = h2Match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? heroTitle;
      }
      
      // Extract first paragraph as subtitle
      final pMatch = RegExp(r'<p>(.*?)</p>').firstMatch(content);
      if (pMatch != null) {
        heroSubtitle = pMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? heroSubtitle;
      }
    }
    
    return HeroSection(
      title: heroTitle,
      subtitle: heroSubtitle,
      imageUrl: heroImageUrl,
      backgroundColor: heroBackgroundColor,
      textColor: Colors.black,
    );
  }

  Widget _buildCountryFlagsSection() {
    // Country flag images from WordPress
    final List<Map<String, String>> countryFlags = [
      {
        'name': 'Emirates',
        'image': 'https://alkhatm.com/wp-content/uploads/2024/05/EMARATI.png',
      },
      {
        'name': 'Kuwait',
        'image': 'https://alkhatm.com/wp-content/uploads/2024/05/KUWAITI.png',
      },
      {
        'name': 'Saudi Arabia',
        'image': 'https://alkhatm.com/wp-content/uploads/2024/05/SAUDI-ARABIA.png',
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth >= 1200 ? 48.0 : (screenWidth >= 800 ? 32.0 : 16.0);
    final verticalPadding = screenWidth >= 800 ? 16.0 : 8.0;
    final imageHeight = screenWidth >= 1200 ? 200.0 : (screenWidth >= 800 ? 180.0 : 150.0);
    final spacing = screenWidth >= 800 ? 20.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Column(
        children: countryFlags.map((country) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: CachedNetworkImage(
              imageUrl: country['image']!,
              width: double.infinity,
              height: imageHeight,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: imageHeight,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: imageHeight,
                child: Icon(
                  Icons.flag, 
                  size: screenWidth >= 800 ? 100 : 80, 
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompanyDescription() {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth >= 1200 ? 48.0 : (screenWidth >= 800 ? 32.0 : 24.0);
    final titleSize = screenWidth >= 1200 ? 24.0 : (screenWidth >= 800 ? 22.0 : 20.0);
    final textSize = screenWidth >= 1200 ? 16.0 : (screenWidth >= 800 ? 15.0 : 14.0);
    final spacing = screenWidth >= 800 ? 16.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Text(
            'AL KHATM GROUP OF COMPANIES',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            'Established in the year 2005, is a ubiquitous brand name in fashion, including traditional gents fashion, kids fashion, uniforms, accessories, perfumes and footwear.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    // Show only first 6 categories (2 rows x 3 columns)
    final displayCategories = _categories.take(6).toList();
    
    // Manual mapping for category images (since WooCommerce categories don't have images)
    String? _getCategoryImage(String categoryName) {
      final baseUrl = 'https://alkhatm.com/wp-content/uploads/2024/08';
      final categoryImages = {
        'SANDALS': '$baseUrl/SANDALS-CAT.png',
        'FRAGRANCES': '$baseUrl/FRAGRANCES-CAT.png',
        'AGAL': '$baseUrl/AGAL-CAT.png',
        'SHAWL': '$baseUrl/SHAWL-CAT.png',
        'BUKHOOR': '$baseUrl/BUKHOOR-CAT.png',
        'HUZAR': '$baseUrl/HUZAR-CAT.png',
      };
      
      // Match category name (case insensitive)
      final key = categoryImages.keys.firstWhere(
        (k) => categoryName.toUpperCase().contains(k),
        orElse: () => '',
      );
      
      return key.isNotEmpty ? categoryImages[key] : null;
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth >= 1200 ? 48.0 : (screenWidth >= 800 ? 32.0 : 16.0);
    
    return Column(
      children: [
        const SectionHeader(
          title: 'Main Categories',
          subtitle: 'Shop by category',
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(
                context,
                mobile: 2,
                tablet: 3,
                desktop: 6,  // Show all 6 categories in one row on iPad 13\" landscape
              ),
              childAspectRatio: screenWidth >= 1200 ? 0.9 : (screenWidth >= 800 ? 0.85 : 0.75),
              crossAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
              mainAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              final imageUrl = category.image?.src ?? _getCategoryImage(category.name);
              
              return CategoryCard(
                name: category.name,
                imageUrl: imageUrl,
                count: category.count,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        categoryId: category.id.toString(),
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeaturedProductsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth >= 1200 ? 48.0 : (screenWidth >= 800 ? 32.0 : 16.0);
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
    final childAspectRatio = screenWidth >= 1200 ? 0.78 : (screenWidth >= 800 ? 0.75 : 0.7);
    final spacing = screenWidth >= 1200 ? 16.0 : (screenWidth >= 800 ? 14.0 : 12.0);
    
    return Column(
      children: [
        SectionHeader(
          title: 'Featured Products',
          subtitle: 'Our best selection',
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FeaturedProductsScreen(),
              ),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: _featuredProducts.length > 4 ? 4 : _featuredProducts.length,
          itemBuilder: (context, index) {
            final product = _featuredProducts[index];
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
      ],
    );
  }

  Widget _buildSaleSection() {
    return Column(
      children: [
        SectionHeader(
          title: 'Sale Items',
          subtitle: 'Limited time offers',
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SaleProductsScreen(),
              ),
            );
          },
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _saleProducts.length,
            itemBuilder: (context, index) {
              final product = _saleProducts[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: ProductCard(
                  name: product.name,
                  price: 'د.إ ${product.price}',
                  originalPrice: 'د.إ ${product.regularPrice}',
                  imageUrl: product.images.isNotEmpty ? product.images.first.src : null,
                  rating: product.averageRating,
                  ratingCount: product.ratingCount,
                  onSale: true,
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

  Widget _buildDynamicContent() {
    if (_homepage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: WordPressContentRenderer(
        page: _homepage!,
        showTitle: false,
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'We Provide High Quality Goods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '- There are some redeeming factors',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFeatureCard(
                  icon: Icons.local_shipping,
                  title: 'FAST DELIVERY',
                  description: 'Once shipped from our ware house, it reaches your door steps with in a week or less depending on your shipping location.',
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(width: 16),
                _buildFeatureCard(
                  icon: Icons.verified,
                  title: 'BEST QUALITY',
                  description: 'We are constantly trying to keep all your favourites available all the time with the best quality materials.',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 16),
                _buildFeatureCard(
                  icon: Icons.design_services,
                  title: 'PERFECT STITCHING',
                  description: 'Our team works from Monday to Saturday ensuring your purchase reaches you at the right time with perfect stitching.',
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1d1722),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutUsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF79B2D5).withOpacity(0.1),
            const Color(0xFF79B2D5).withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'About Us',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'We Have Over 17+ Years of Expertise with satisfied customers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'AL KHATM GROUP OF COMPANIES, established in the year 2005, is a ubiquitous brand name in fashion, including traditional gents fashion, kids fashion, uniforms, accessories, perfumes and footwear. Rooted in tradition and inspired by fashion, our line of signature products represents world class quality. Being fully customer oriented, we provide the best in class services, from in-showroom hospitality to customizable products, branch to branch delivery and replacement guarantee with the promise of outstanding quality.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('HAPPY CLIENTS', '1000+'),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              _buildStatCard('PRODUCTS', '5000+'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductShowcaseSection() {
    final List<Map<String, String>> showcaseImages = [
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/SHAWL-CAT-150x150.png',
        'alt': 'SHAWL - CAT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/SANDALS-CAT-150x150.png',
        'alt': 'SANDALS - CAT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/HUZAR-CAT-150x150.png',
        'alt': 'HUZAR - CAT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/FRAGRANCES-CAT-150x150.png',
        'alt': 'FRAGRANCES - CAT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/BUKHOOR-CAT-150x150.png',
        'alt': 'BUKHOOR - CAT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/AGAL-CAT-150x150.png',
        'alt': 'AGAL - CAT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/2338-WTTN-1-150x150.png',
        'alt': 'SANDAL PRODUCT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/2230-BKTN-4-150x150.png',
        'alt': 'SANDAL PRODUCT'
      },
      {
        'url': 'https://alkhatm.com/wp-content/uploads/2024/08/SH02-3-150x150.png',
        'alt': 'SHAWL PRODUCT'
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _showcasePageController,
              itemCount: showcaseImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentShowcasePage = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildProductShowcaseCard(
                    imageUrl: showcaseImages[index]['url']!,
                    altText: showcaseImages[index]['alt']!,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              showcaseImages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentShowcasePage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentShowcasePage == index
                      ? const Color(0xFF79B2D5)
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductShowcaseCard({
    required String imageUrl,
    required String altText,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 160,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 160,
              height: 180,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    altText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF79B2D5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMapsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 450,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Google Maps placeholder - click to open in browser/app
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse('https://maps.google.com/?q=Al+khatm+gents+tailoring,Ajman');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF79B2D5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF79B2D5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.map, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Open in Google Maps',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Info card overlay matching website design
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Al khatm gents tailoring AJM...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a1a),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '21 Beirut st - Ajman Industrial 1 -\nAjman',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const Icon(Icons.star_half, color: Colors.amber, size: 14),
                              const Icon(Icons.star_border, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '3.6',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {},
                            child: const Text(
                              '61 reviews',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1a73e8),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openGoogleMaps,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1a73e8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Directions',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=25.3848301,55.477339&query_place_id=ChIJzdy2ERdT7z8R8O9RLXrmbOA',
    );
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactSection() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email, 'info@alkhatm.com'),
          const SizedBox(height: 8),
          _buildContactItem(Icons.phone, '+971 56 681 0269'),
          const SizedBox(height: 8),
          _buildContactItem(
            Icons.location_on,
            'Al Khatm Gents Tailoring LLC\nExhibition showroom no: 47\nAjman industrial-1 UAE',
          ),
          const SizedBox(height: 16),
          const Text(
            'Over 17+ Years of Expertise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalPadding = screenWidth >= 1200 ? 56.0 : (screenWidth >= 800 ? 48.0 : 40.0);
    final horizontalPadding = screenWidth >= 1200 ? 48.0 : (screenWidth >= 800 ? 32.0 : 16.0);
    final cardHeight = screenWidth >= 1200 ? 320.0 : (screenWidth >= 800 ? 300.0 : 280.0);
    final copyrightSize = screenWidth >= 800 ? 14.0 : 12.0;
    
    return Container(
      color: const Color(0xFF1a1a1a),
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
      child: Column(
        children: [
          // Slideable footer cards
          SizedBox(
            height: cardHeight,
            child: PageView(
              controller: _footerPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentFooterPage = index;
                });
              },
              children: [
                _buildFooterCard(
                  'ABOUT US',
                  'AL KHATM GROUP OF COMPANIES, established in the year 2005, is a ubiquitous brand name in fashion, including traditional gents fashion, kids fashion, uniforms, accessories, perfumes and footwear.',
                  Icons.info_outline,
                  showLogo: true,
                ),
                _buildContactInfoCard(),
                _buildQuickLinksCard(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentFooterPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentFooterPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          // Copyright
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} AL KHATM. All rights reserved.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: copyrightSize,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCard(String title, String content, IconData icon, {bool showLogo = false, bool showSocialMedia = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth >= 1200 ? 32.0 : (screenWidth >= 800 ? 28.0 : 24.0);
    final logoHeight = screenWidth >= 1200 ? 70.0 : (screenWidth >= 800 ? 65.0 : 60.0);
    final iconSize = screenWidth >= 800 ? 32.0 : 28.0;
    final titleSize = screenWidth >= 1200 ? 20.0 : (screenWidth >= 800 ? 19.0 : 18.0);
    final contentSize = screenWidth >= 1200 ? 16.0 : (screenWidth >= 800 ? 15.0 : 14.0);
    final borderRadius = screenWidth >= 800 ? 20.0 : 16.0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth >= 800 ? 12 : 8),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLogo)
            Center(
              child: CachedNetworkImage(
                imageUrl: 'https://alkhatm.com/wp-content/uploads/2024/05/Untitled_design__1_-removebg-preview.png',
                height: logoHeight,
                fit: BoxFit.contain,
                placeholder: (context, url) => SizedBox(
                  height: logoHeight,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => SizedBox(
                  height: logoHeight,
                  child: const Center(
                    child: Icon(Icons.image, size: 30, color: Colors.white24),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Icon(icon, color: const Color(0xFF79B2D5), size: iconSize),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          SizedBox(height: screenWidth >= 800 ? 20 : 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: contentSize,
                      height: 1.6,
                    ),
                  ),
                  if (showSocialMedia) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Follow Us:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: contentSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildBrandSocialIcon(FontAwesomeIcons.facebook, 'https://web.facebook.com/people/Alkhatm/61557712551426/', const Color(0xFF1877F2)),
                        const SizedBox(width: 12),
                        _buildBrandSocialIcon(FontAwesomeIcons.whatsapp, 'https://wa.me/971566810269', const Color(0xFF25D366)),
                        const SizedBox(width: 12),
                        _buildBrandSocialIcon(FontAwesomeIcons.snapchat, 'https://www.snapchat.com/@alkhatem279', const Color(0xFFFFFC00), iconColor: Colors.black),
                        const SizedBox(width: 12),
                        _buildBrandSocialIcon(FontAwesomeIcons.instagram, 'https://www.instagram.com/', const Color(0xFFE4405F)),
                        const SizedBox(width: 12),
                        _buildBrandSocialIcon(FontAwesomeIcons.twitter, 'https://twitter.com/', const Color(0xFF1DA1F2)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: const Color(0xFF79B2D5), size: 28),
              const SizedBox(width: 12),
              const Text(
                'CONTACT INFO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone, color: Color(0xFF79B2D5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _contactPhone,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Email
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.email, color: Color(0xFF79B2D5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _contactEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF79B2D5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _contactAddress,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: const Color(0xFF79B2D5), size: 28),
              const SizedBox(width: 12),
              const Text(
                'QUICK LINKS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick links in rows (side by side)
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildQuickLinkItem('Home'),
                      _buildQuickLinkItem('About Us'),
                      _buildQuickLinkItem('Policies'),
                      _buildQuickLinkItem('Contact Us'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Social Media
                  const Text(
                    'Connect With Us:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: _buildDynamicSocialIcons(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkItem(String title) {
    return InkWell(
      onTap: () {
        if (title == 'Home') {
          // Already on home, just scroll to top
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (title == 'About Us') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PageDetailScreen(pageId: 805),
            ),
          );
        } else if (title == 'Policies') {
          // Navigate to policies - could show a menu or specific policy
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PageDetailScreen(pageId: 976), // Terms & Conditions
            ),
          );
        } else if (title == 'Contact Us') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PageDetailScreen(pageId: 807),
            ),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForLink(title),
            color: const Color(0xFF79B2D5),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF79B2D5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF79B2D5),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLink(String title) {
    switch (title) {
      case 'Home':
        return Icons.home;
      case 'About Us':
        return Icons.info;
      case 'Policies':
        return Icons.description;
      case 'Contact Us':
        return Icons.contact_mail;
      default:
        return Icons.link;
    }
  }

  List<Widget> _buildDynamicSocialIcons() {
    final icons = <Widget>[];
    
    // Define social config in desired order
    final socialConfig = [
      {
        'key': 'facebook',
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'iconColor': Colors.white,
      },
      {
        'key': 'whatsapp',
        'icon': FontAwesomeIcons.whatsapp,
        'color': const Color(0xFF25D366),
        'iconColor': Colors.white,
      },
      {
        'key': 'snapchat',
        'icon': FontAwesomeIcons.snapchat,
        'color': const Color(0xFFFFFC00),
        'iconColor': Colors.black,
      },
      {
        'key': 'instagram',
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE4405F),
        'iconColor': Colors.white,
      },
    ];
    
    for (var config in socialConfig) {
      final url = _socialLinks[config['key'] as String];
      if (url != null && url.isNotEmpty) {
        icons.add(_buildBrandSocialIcon(
          config['icon'] as IconData,
          url,
          config['color'] as Color,
          iconColor: config['iconColor'] as Color,
        ));
        icons.add(const SizedBox(width: 12));
      }
    }
    
    // Remove last spacing if icons exist
    if (icons.isNotEmpty && icons.last is SizedBox) {
      icons.removeLast();
    }
    
    return icons;
  }

  Widget _buildBrandSocialIcon(IconData icon, String url, Color color, {Color iconColor = Colors.white}) {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 26,
        ),
      ),
    );
  }
}


