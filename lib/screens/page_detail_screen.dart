import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/wordpress_service.dart';
import '../models/wordpress_models.dart';
import '../widgets/content_widgets.dart';
import 'main_screen.dart';

class PageDetailScreen extends StatefulWidget {
  final int pageId;

  const PageDetailScreen({super.key, required this.pageId});

  @override
  State<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends State<PageDetailScreen> {
  final WordPressService _service = WordPressService();
  Post? _page;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  String _fullPageHtml = '';

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _service.getPage(widget.pageId);

      if (response.isSuccess && response.data != null) {
        // For contact page, also fetch full HTML to get footer social links
        if (response.data!.title.toLowerCase().contains('contact')) {
          try {
            final pageResponse = await http.get(
              Uri.parse(response.data!.url),
            );
            if (pageResponse.statusCode == 200) {
              _fullPageHtml = pageResponse.body;
            }
          } catch (e) {
            // Fallback to just content if full page fetch fails
            _fullPageHtml = response.data!.content;
          }
        }
        
        setState(() {
          _page = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading page: $e';
        _isLoading = false;
      });
    }
  }

  bool _isContactPage() {
    return _page?.title.toLowerCase().contains('contact') ?? false;
  }

  bool _isAboutUsPage() {
    return _page?.title.toLowerCase().contains('about') ?? false;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
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
    final addressMatch = RegExp(r'Al Khatem[^<]*?UAE', caseSensitive: false).firstMatch(content);
    return addressMatch?.group(0) ?? 'Al Khatem Gents Tailoring LLC, Exhibition showroom no: 47, Ajman industrial-1, UAE';
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
    
    // Extract Twitter/X
    final twitterMatch = RegExp(r'(twitter\.com|x\.com)/[^\s<>]+').firstMatch(content);
    if (twitterMatch != null) {
      socialLinks['twitter'] = 'https://${twitterMatch.group(0)}';
    }
    
    // Extract Tumblr
    final tumblrMatch = RegExp(r'tumblr\.com/[^\s<>]+').firstMatch(content);
    if (tumblrMatch != null) {
      socialLinks['tumblr'] = tumblrMatch.group(0)!.startsWith('http') 
          ? tumblrMatch.group(0)! 
          : 'https://${tumblrMatch.group(0)}';
    }
    
    return socialLinks;
  }

  Widget _buildContactUsPage() {
    final contentToScan = _fullPageHtml.isNotEmpty ? _fullPageHtml : _page!.content;
    final phone = _extractPhone(contentToScan);
    final email = _extractEmail(contentToScan);
    final address = _extractAddress(contentToScan);
    final phoneClean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final socialLinks = _extractSocialLinks(contentToScan);

    return RefreshIndicator(
      onRefresh: _loadPage,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF79B2D5), Color(0xFF5A9BC4)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.contact_mail_rounded,
                      size: 60,
                      color: Color(0xFF79B2D5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Get In Touch',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'d love to hear from you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Contact Cards Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Phone Card
                  _buildContactCard(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Phone',
                    subtitle: phone,
                    onTap: () => _launchUrl('tel:$phoneClean'),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp Card
                  _buildContactCard(
                    icon: FontAwesomeIcons.whatsapp,
                    iconColor: const Color(0xFF25D366),
                    title: 'WhatsApp',
                    subtitle: phone,
                    onTap: () => _launchUrl('https://wa.me/$phoneClean'),
                  ),
                  const SizedBox(height: 16),

                  // Email Card
                  _buildContactCard(
                    icon: Icons.email_rounded,
                    iconColor: const Color(0xFFE53935),
                    title: 'Email',
                    subtitle: email,
                    onTap: () => _launchUrl('mailto:$email'),
                  ),
                  const SizedBox(height: 16),

                  // Address Card
                  _buildContactCard(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2196F3),
                    title: 'Visit Our Showroom',
                    subtitle: address,
                    multiline: true,
                    onTap: () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'),
                  ),

                  const SizedBox(height: 32),

                  // Company Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF79B2D5).withOpacity(0.1),
                          const Color(0xFF79B2D5).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF79B2D5).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 48,
                          color: Color(0xFF79B2D5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AL KHATEM GROUP OF COMPANIES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF79B2D5),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Established in 2005',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'A ubiquitous brand name in fashion, including traditional gents fashion, kids fashion, uniforms, accessories, perfumes and footwear.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Social Media Section
                  if (socialLinks.isNotEmpty) ...[
                    const Text(
                      'Follow Us',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildSocialButtons(socialLinks, phoneClean)
                          .map((button) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: button,
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Information Note
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'If you have any questions or suggestions, please contact us at $email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade900,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutUsPage() {
    // Remove stats from content since we show them as cards
    String cleanedContent = _page!.content
        .replaceAll(RegExp(r'<h2>\s*100 Million\+\s*</h2>'), '')
        .replaceAll(RegExp(r'<p>\s*Products Sold\s*</p>'), '')
        .replaceAll(RegExp(r'<h2>\s*100%\s*</h2>'), '')
        .replaceAll(RegExp(r'<p>\s*Satisfied Costumers\s*</p>'), '')
        .replaceAll(RegExp(r'<h2>\s*5\s*</h2>'), '')
        .replaceAll(RegExp(r'<h2>\s*Awards Winning\s*</h2>'), '');
    
    Post cleanedPage = Post(
      id: _page!.id,
      title: _page!.title,
      content: cleanedContent,
      excerpt: _page!.excerpt,
      date: _page!.date,
      modified: _page!.modified,
      slug: _page!.slug,
      status: _page!.status,
      type: _page!.type,
      author: _page!.author,
      featuredImage: _page!.featuredImage,
      firstContentImage: _page!.firstContentImage,
      categories: _page!.categories,
      tags: _page!.tags,
      url: _page!.url,
      commentCount: _page!.commentCount,
      comments: _page!.comments,
    );

    return RefreshIndicator(
      onRefresh: _loadPage,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF79B2D5),
                    const Color(0xFF5A9BC4),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const Icon(
                      Icons.business_center,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _page!.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards Carousel
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Our Achievements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PageView(
                padEnds: false,
                controller: PageController(viewportFraction: 0.85),
                children: [
                  _buildStatCard(
                    icon: Icons.inventory_2,
                    title: '100M+',
                    subtitle: 'Products Sold',
                    color: const Color(0xFF79B2D5),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF79B2D5), Color(0xFF5A9BC4)],
                    ),
                  ),
                  _buildStatCard(
                    icon: Icons.sentiment_very_satisfied,
                    title: '100%',
                    subtitle: 'Satisfied Customers',
                    color: const Color(0xFF4CAF50),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                    ),
                  ),
                  _buildStatCard(
                    icon: Icons.emoji_events,
                    title: '5',
                    subtitle: 'Awards Winning',
                    color: const Color(0xFFFF9800),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WordPressContentRenderer(
                page: cleanedPage,
                showTitle: false,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool multiline = false,
  }) {
    return Card(
      elevation: 3,
      shadowColor: iconColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: multiline ? 13 : 14,
                        color: Colors.grey[700],
                        height: multiline ? 1.5 : 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSocialButtons(Map<String, String> socialLinks, String phoneClean) {
    final buttons = <Widget>[];
    
    // Define social media configuration
    final socialConfig = {
      'whatsapp': {
        'icon': FontAwesomeIcons.whatsapp,
        'color': const Color(0xFF25D366),
        'label': 'WhatsApp',
        'url': socialLinks['whatsapp'] ?? 'https://wa.me/$phoneClean',
      },
      'facebook': {
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'label': 'Facebook',
        'url': socialLinks['facebook'],
      },
      'instagram': {
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE4405F),
        'label': 'Instagram',
        'url': socialLinks['instagram'],
      },
      'snapchat': {
        'icon': FontAwesomeIcons.snapchat,
        'color': const Color(0xFFFFFC00),
        'label': 'Snapchat',
        'url': socialLinks['snapchat'],
      },
      'twitter': {
        'icon': FontAwesomeIcons.xTwitter,
        'color': Colors.black,
        'label': 'Twitter',
        'url': socialLinks['twitter'],
      },
      'tumblr': {
        'icon': FontAwesomeIcons.tumblr,
        'color': const Color(0xFF35465C),
        'label': 'Tumblr',
        'url': socialLinks['tumblr'],
      },
    };
    
    // Build buttons only for available social links
    for (final entry in socialConfig.entries) {
      final url = entry.value['url'] as String?;
      if (url != null && url.isNotEmpty) {
        buttons.add(
          _buildSocialButton(
            icon: entry.value['icon'] as IconData,
            color: entry.value['color'] as Color,
            label: entry.value['label'] as String,
            onTap: () => _launchUrl(url),
          ),
        );
      }
    }
    
    return buttons;
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color == const Color(0xFFFFFC00) ? Colors.black : color,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_page?.title ?? 'Loading...'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPage,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _page == null
                  ? const Center(child: Text('Page not found'))
                  : _isContactPage()
                      ? _buildContactUsPage()
                      : _isAboutUsPage()
                          ? _buildAboutUsPage()
                          : RefreshIndicator(
                          onRefresh: _loadPage,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Page Title
                                Text(
                                  _page!.title,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF79B2D5),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(thickness: 2),
                                const SizedBox(height: 16),
                                // Page Content
                                WordPressContentRenderer(
                                  page: _page!,
                                  showTitle: false,
                                ),
                              ],
                            ),
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
