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
  final String type;
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
  final List<ProductVariation> variations;
  final List<ProductAttribute> attributes;

  WooProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.type = 'simple',
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
    this.variations = const [],
    this.attributes = const [],
  });

  bool get isVariable => type == 'variable';

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    return WooProduct(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? 'simple',
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
      variations: (json['variations'] as List?)
              ?.map((variation) => ProductVariation.fromJson(variation))
              .toList() ??
          [],
      attributes: (json['attributes'] as List?)
              ?.map((attr) => ProductAttribute.fromJson(attr))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
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
      'variations': variations.map((v) => v.toJson()).toList(),
      'attributes': attributes.map((a) => a.toJson()).toList(),
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

class ProductVariation {
  final int id;
  final String sku;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final String stockStatus;
  final int? stockQuantity;
  final Map<String, String> attributes;
  final List<ProductImage> images;
  final bool inStock;
  final bool isPurchasable;

  ProductVariation({
    required this.id,
    required this.sku,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.stockStatus,
    this.stockQuantity,
    required this.attributes,
    required this.images,
    required this.inStock,
    required this.isPurchasable,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    // Convert attributes to Map<String, String>
    Map<String, String> attrs = {};
    if (json['attributes'] is Map) {
      (json['attributes'] as Map).forEach((key, value) {
        attrs[key.toString()] = value.toString();
      });
    }

    return ProductVariation(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sku: json['sku']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      regularPrice: json['regular_price']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] == true || json['on_sale'] == 'true',
      stockStatus: json['stock_status']?.toString() ?? '',
      stockQuantity: json['stock_quantity'] is int 
          ? json['stock_quantity'] 
          : int.tryParse(json['stock_quantity']?.toString() ?? ''),
      attributes: attrs,
      images: (json['images'] as List?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
      inStock: json['in_stock'] == true || json['in_stock'] == 'true',
      isPurchasable: json['is_purchasable'] == true || json['is_purchasable'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'on_sale': onSale,
      'stock_status': stockStatus,
      'stock_quantity': stockQuantity,
      'attributes': attributes,
      'images': images.map((img) => img.toJson()).toList(),
      'in_stock': inStock,
      'is_purchasable': isPurchasable,
    };
  }

  String getAttributeValue(String attributeName) {
    // Try exact match first
    if (attributes.containsKey(attributeName)) {
      return attributes[attributeName]!;
    }
    
    // Try case-insensitive match
    final lowerName = attributeName.toLowerCase();
    for (var entry in attributes.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    
    return '';
  }
}

class ProductAttribute {
  final int id;
  final String name;
  final String slug;
  final List<AttributeOption> options;
  final bool visible;
  final bool isColor;

  ProductAttribute({
    required this.id,
    required this.name,
    required this.slug,
    required this.options,
    required this.visible,
    this.isColor = false,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      options: (json['options'] as List?)
              ?.map((opt) => AttributeOption.fromJson(opt))
              .toList() ??
          [],
      visible: json['visible'] == true || json['visible'] == 'true',
      isColor: json['is_color'] == true || json['is_color'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'options': options.map((opt) => opt.toJson()).toList(),
      'visible': visible,
      'is_color': isColor,
    };
  }
}

class AttributeOption {
  final String slug;
  final String name;
  final String? color;

  AttributeOption({
    required this.slug,
    required this.name,
    this.color,
  });

  factory AttributeOption.fromJson(Map<String, dynamic> json) {
    return AttributeOption(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'color': color,
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
    String? orderby,  // 🆕 Added orderby parameter (popularity, rating, date, price, price-desc, title)
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (onSale != null) 'on_sale': onSale.toString(),
        if (featured != null) 'featured': featured.toString(),
        if (category != null) 'category': category,
        if (orderby != null) 'orderby': orderby,  // 🆕 Pass orderby to API
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
        'hide_empty': 'false',  // ✅ Show all categories including empty ones
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
  Future<List<WooProduct>> getFeaturedProducts({int page = 1, int perPage = 100}) async {
    return getProducts(featured: true, page: page, perPage: perPage);
  }

  // Get sale products
  Future<List<WooProduct>> getSaleProducts({int page = 1, int perPage = 10, String? orderby}) async {
    return getProducts(onSale: true, page: page, perPage: perPage, orderby: orderby);
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

      final url = _buildBridgeUrl('woo_create_order', {});
      print('📡 [API] Posting order to: $url');
      print('📦 [API] Order data: ${jsonEncode(orderData).substring(0, 200)}...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      ).timeout(ApiConfig.timeout);

      print('📡 [API] Response status: ${response.statusCode}');
      print('📡 [API] Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          print('✅ [API] Order created successfully!');
          return jsonResponse['data'];
        } else {
          print('❌ [API] Order creation failed: ${jsonResponse['message']}');
        }
      } else {
        print('❌ [API] HTTP error: ${response.statusCode}');
        print('   Body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ [API] Exception creating order: $e');
      return null;
    }
  }
}
