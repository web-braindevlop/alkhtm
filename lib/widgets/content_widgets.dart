import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wordpress_models.dart';
import '../config/api_config.dart';

/// Dynamically renders WordPress/Elementor content
class WordPressContentRenderer extends StatelessWidget {
  final Post page;
  final bool showTitle;

  const WordPressContentRenderer({
    super.key,
    required this.page,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image if available
          if (page.featuredImage != null)
            _buildHeroImage(page.featuredImage!),

          // Title (optional)
          if (showTitle)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

          // Dynamic HTML Content with Elementor support
          _buildHtmlContent(context, page.content),
        ],
      ),
    );
  }

  Widget _buildHeroImage(FeaturedImage image) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: image.large,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, size: 50),
        ),
      ),
    );
  }

  Widget _buildHtmlContent(BuildContext context, String htmlContent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: HtmlWidget(
        htmlContent,
        
        // Custom styling
        textStyle: const TextStyle(
          fontSize: 15,
          height: 1.7,
          color: Colors.black87,
        ),
        
        // Custom styles for specific HTML elements
        customStylesBuilder: (element) {
          // Headings
          if (element.localName == 'h1') {
            return {
              'font-size': '26px',
              'font-weight': 'bold',
              'color': '#79B2D5',
              'margin-top': '24px',
              'margin-bottom': '12px',
            };
          }
          if (element.localName == 'h2') {
            return {
              'font-size': '22px',
              'font-weight': 'bold',
              'color': '#79B2D5',
              'margin-top': '20px',
              'margin-bottom': '10px',
            };
          }
          if (element.localName == 'h3') {
            return {
              'font-size': '18px',
              'font-weight': '600',
              'color': '#333333',
              'margin-top': '16px',
              'margin-bottom': '8px',
            };
          }
          
          // Paragraphs
          if (element.localName == 'p') {
            return {
              'margin-bottom': '16px',
              'line-height': '1.7',
              'text-align': 'justify',
            };
          }
          
          // Lists
          if (element.localName == 'ul' || element.localName == 'ol') {
            return {
              'margin-bottom': '16px',
              'padding-left': '20px',
            };
          }
          if (element.localName == 'li') {
            return {
              'margin-bottom': '8px',
              'line-height': '1.6',
            };
          }
          
          // Strong/Bold text
          if (element.localName == 'strong' || element.localName == 'b') {
            return {
              'font-weight': 'bold',
              'color': '#000000',
            };
          }
          
          // Links
          if (element.localName == 'a') {
            return {
              'color': '#79B2D5',
              'text-decoration': 'underline',
            };
          }
          
          return null;
        },

        // Custom widget builder for advanced elements
        customWidgetBuilder: (element) {
        // Handle images
        if (element.localName == 'img') {
          final src = element.attributes['src'] ?? '';
          if (src.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CachedNetworkImage(
                imageUrl: _fixImageUrl(src),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 60),
                ),
              ),
            );
          }
        }

        // Handle buttons
        if (element.localName == 'a' && 
            (element.className.contains('button') || 
             element.className.contains('btn') ||
             element.className.contains('elementor-button'))) {
          final href = element.attributes['href'] ?? '';
          final text = element.text;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () => _launchUrl(href),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return null;
      },

      // Handle link taps
      onTapUrl: (url) {
        _launchUrl(url);
        return true;
      },

      // Render mode for better performance
      renderMode: RenderMode.column,
      ),
    );
  }

  String _fixImageUrl(String url) {
    // If relative URL, make it absolute
    if (!url.startsWith('http')) {
      return '${ApiConfig.baseUrl}$url';
    }
    return url;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Hero Section Widget - Card style with image on right
class HeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? textColor;

  const HeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Always use large screen layout (side-by-side) for iPhone and above
    // Use small screen layout (stacked) only for very small screens (below 320px)
    final screenWidth = MediaQuery.of(context).size.width;
    final useStackedLayout = screenWidth < 320; // Stack only on screens smaller than iPhone SE

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: backgroundColor ?? const Color(0xFF79B2D5), // Correct blue background #79b2d5
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: useStackedLayout
            ? _buildSmallScreenLayout(context)
            : _buildLargeScreenLayout(context), // Side-by-side layout for all iPhones
      ),
    );
  }

  // Layout for large screens (web/tablet) - image on right
  Widget _buildLargeScreenLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 20.0 : 32.0,
        vertical: screenWidth < 600 ? 24.0 : 32.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Text content (55% width)
          Expanded(
            flex: 55,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title - Responsive size
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth < 600 ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    color: textColor ?? Colors.black,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: screenWidth < 600 ? 12 : 16),
                // Subtitle/Description - All content visible
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: screenWidth < 600 ? 12 : 14,
                    fontWeight: FontWeight.w400,
                    color: (textColor ?? Colors.black).withOpacity(0.8),
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          
          // Right side - Image (45% width - increased)
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Expanded(
              flex: 45,
              child: Padding(
                padding: EdgeInsets.only(
                  right: screenWidth < 600 ? 0.0 : 8.0,
                  top: screenWidth < 600 ? 20.0 : 24.0,
                  bottom: screenWidth < 600 ? 12.0 : 16.0,
                  left: screenWidth < 600 ? 8.0 : 12.0,
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    // Image load error
                    return Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, 
                            size: 48, 
                            color: (textColor ?? Colors.black).withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: TextStyle(
                              color: (textColor ?? Colors.black).withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Layout for small screens (mobile) - stacked
  Widget _buildSmallScreenLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text content
        Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: textColor ?? Colors.black,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: (textColor ?? Colors.black).withOpacity(0.75),
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        
        // Image below text on mobile
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: SizedBox(
              height: 280,
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                errorWidget: (context, url, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, 
                          size: 48, 
                          color: (textColor ?? Colors.black).withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: (textColor ?? Colors.black).withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Category Card Widget
class CategoryCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int count;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.category, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.category, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$count items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

/// Product Card for WooCommerce
class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String? originalPrice;
  final String? imageUrl;
  final bool onSale;
  final VoidCallback onTap;
  final double? rating;
  final int? ratingCount;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.onSale = false,
    required this.onTap,
    this.rating,
    this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.shopping_bag, size: 40),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.shopping_bag, size: 40),
                        ),
                  if (onSale)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Star Rating - Always show even if no ratings
                        if (rating != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: StarRating(
                              rating: rating!,
                              ratingCount: ratingCount ?? 0,
                              size: 12,
                              showCount: false,
                            ),
                          ),
                        // Price
                        Row(
                          children: [
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: onSale ? Colors.red : Colors.black,
                              ),
                            ),
                            if (originalPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                originalPrice!,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

/// Star Rating Widget - displays product ratings
class StarRating extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double size;
  final Color color;
  final bool showCount;

  const StarRating({
    super.key,
    required this.rating,
    this.ratingCount = 0,
    this.size = 16,
    this.color = Colors.amber,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            // Full star
            return Icon(Icons.star, size: size, color: color);
          } else if (index < rating) {
            // Half star
            return Icon(Icons.star_half, size: size, color: color);
          } else {
            // Empty star
            return Icon(Icons.star_border, size: size, color: color);
          }
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            ratingCount > 0 ? '($ratingCount)' : '(0)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive Star Rating Widget - allows users to rate products
class RatingInput extends StatefulWidget {
  final Function(int rating) onRatingChanged;
  final int initialRating;
  final double size;

  const RatingInput({
    super.key,
    required this.onRatingChanged,
    this.initialRating = 0,
    this.size = 40,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1;
            });
            widget.onRatingChanged(index + 1);
          },
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}
