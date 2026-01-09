import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Helper function to build API bridge URL
String _buildBridgeUrl(String action, Map<String, String>? params) {
  final queryParams = {
    'action': action,
    ...?params,
  };
  return Uri.parse(ApiConfig.apiUrl)
      .replace(queryParameters: queryParams)
      .toString();
}

class WooProduct {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String shortDescription;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final List<ProductImage> images;
  final List<ProductCategory> categories;
  final bool inStock;
  final double averageRating;
  final int ratingCount;
  final List<int> relatedIds;

  WooProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.images,
    required this.categories,
    required this.inStock,
    required this.averageRating,
    required this.ratingCount,
    this.relatedIds = const [],
  });

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    return WooProduct(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      regularPrice: json['regular_price']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] == true || json['on_sale'] == 'true',
      images: (json['images'] as List?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
      categories: (json['categories'] as List?)
              ?.map((cat) => ProductCategory.fromJson(cat))
              .toList() ??
          [],
      inStock: json['stock_status'] == 'instock',
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      ratingCount: json['rating_count'] is int 
          ? json['rating_count'] 
          : int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0,
      relatedIds: (json['related_ids'] as List?)
              ?.map((id) => id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0)
              .where((id) => id > 0)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'on_sale': onSale,
      'images': images.map((img) => img.toJson()).toList(),
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'stock_status': inStock ? 'instock' : 'outofstock',
      'average_rating': averageRating.toString(),
      'rating_count': ratingCount,
      'related_ids': relatedIds,
    };
  }
}

class ProductImage {
  final int id;
  final String src;
  final String name;

  ProductImage({
    required this.id,
    required this.src,
    required this.name,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      src: json['src']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
      'name': name,
    };
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String slug;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class WooCategory {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int count;
  final CategoryImage? image;

  WooCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.count,
    this.image,
  });

  factory WooCategory.fromJson(Map<String, dynamic> json) {
    return WooCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      image: json['image'] != null
          ? CategoryImage.fromJson(json['image'])
          : null,
    );
  }
}

class CategoryImage {
  final int id;
  final String src;

  CategoryImage({
    required this.id,
    required this.src,
  });

  factory CategoryImage.fromJson(Map<String, dynamic> json) {
    return CategoryImage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      src: json['src']?.toString() ?? '',
    );
  }
}

class WooCommerceService {
  // Get all products
  Future<List<WooProduct>> getProducts({
    int page = 1,
    int perPage = 10,
    bool? onSale,
    bool? featured,
    String? category,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (onSale != null) 'on_sale': onSale.toString(),
        if (featured != null) 'featured': featured.toString(),
        if (category != null) 'category': category,
      };

      final url = _buildBridgeUrl('woo_products', params);
      final uri = Uri.parse(url);
      print('📡 [API] Calling getProducts: $url');
      final startTime = DateTime.now();
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      print('✓ [API] getProducts response received in ${DateTime.now().difference(startTime).inMilliseconds}ms');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> products = jsonResponse['data']['products'] ?? [];
          
          return products.map((json) => WooProduct.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get single product
  Future<WooProduct?> getProduct(int productId) async {
    try {
      final url = _buildBridgeUrl('woo_product', {'id': productId.toString()});
      final uri = Uri.parse(url);
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return WooProduct.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get product categories
  Future<List<WooCategory>> getCategories() async {
    try {
      final params = {
        'per_page': '100',
        'hide_empty': 'true',
      };
      
      final url = _buildBridgeUrl('woo_categories', params);
      final uri = Uri.parse(url);
      print('📡 [API] Calling getCategories: $url');
      final startTime = DateTime.now();
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      print('✓ [API] getCategories response received in ${DateTime.now().difference(startTime).inMilliseconds}ms');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> categories = jsonResponse['data']['categories'] ?? [];
          return categories.map((json) => WooCategory.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get featured products
  Future<List<WooProduct>> getFeaturedProducts({int page = 1, int perPage = 10}) async {
    return getProducts(featured: true, page: page, perPage: perPage);
  }

  // Get sale products
  Future<List<WooProduct>> getSaleProducts({int page = 1, int perPage = 10}) async {
    return getProducts(onSale: true, page: page, perPage: perPage);
  }

  // Get products by category
  Future<List<WooProduct>> getProductsByCategory(
    String categoryId, {
    int page = 1,
    int perPage = 10,
  }) async {
    return getProducts(
      category: categoryId,
      page: page,
      perPage: perPage,
    );
  }

  // Get products by IDs (for related products)
  Future<List<WooProduct>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      final params = {
        'include': ids.join(','),
        'per_page': ids.length.toString(),
      };
      
      final url = _buildBridgeUrl('woo_products', params);
      final uri = Uri.parse(url);
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> products = jsonResponse['data']['products'] ?? [];
          return products.map((json) => WooProduct.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Search products
  Future<List<WooProduct>> searchProducts(String query) async {
    try {
      final params = {
        'search': query,
        'per_page': '20',
      };
      
      final url = _buildBridgeUrl('woo_products', params);
      final uri = Uri.parse(url);
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> products = jsonResponse['data']['products'] ?? [];
          return products.map((json) => WooProduct.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create order
  Future<Map<String, dynamic>?> createOrder({
    required List<Map<String, dynamic>> lineItems,
    required Map<String, String> billing,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Cash on Delivery',
    String? customerNote,
  }) async {
    try {
      final orderData = {
        'payment_method': paymentMethod,
        'payment_method_title': paymentMethodTitle,
        'set_paid': paymentMethod == 'cod' ? 'false' : 'false',
        'billing': billing,
        'line_items': lineItems,
        'customer_note': customerNote ?? '',
      };

      final response = await http.post(
        Uri.parse(_buildBridgeUrl('woo_create_order', {})),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
