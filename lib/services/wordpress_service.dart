import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/wordpress_models.dart';

class WordPressService {
  // Get site information
  Future<ApiResponse<SiteInfo>> getSiteInfo() async {
    try {
      final url = ApiConfig.buildUrl(ApiConfig.siteInfo);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse.fromJson(
          json,
          (data) => SiteInfo.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to load site info: ${response.statusCode}',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get all posts with pagination
  Future<ApiResponse<PaginatedResponse<Post>>> getPosts({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final params = {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final url = ApiConfig.buildUrl(ApiConfig.posts, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final posts = (data['posts'] as List)
              .map((post) => Post.fromJson(post))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: posts, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load posts',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get single post by ID
  Future<ApiResponse<Post>> getPost(int id) async {
    try {
      final url = ApiConfig.buildUrl(ApiConfig.post, params: {'id': id});
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse.fromJson(
          json,
          (data) => Post.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to load post',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get all pages
  Future<ApiResponse<PaginatedResponse<Post>>> getPages({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final params = {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final url = ApiConfig.buildUrl(ApiConfig.pages, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final pages = (data['pages'] as List)
              .map((page) => Post.fromJson(page))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: pages, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load pages',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get single page by ID
  Future<ApiResponse<Post>> getPage(int id) async {
    try {
      final url = ApiConfig.buildUrl(ApiConfig.page, params: {'id': id});
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        return ApiResponse.fromJson(
          json,
          (data) => Post.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to load page - HTTP ${response.statusCode}',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get all categories
  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final url = ApiConfig.buildUrl(ApiConfig.categories);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final categories = (json['data'] as List)
              .map((cat) => Category.fromJson(cat))
              .toList();

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: categories,
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load categories',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get posts by category
  Future<ApiResponse<PaginatedResponse<Post>>> getPostsByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final params = {
        'id': categoryId,
        'page': page,
        'per_page': perPage,
      };

      final url = ApiConfig.buildUrl(ApiConfig.categoryPosts, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final posts = (data['posts'] as List)
              .map((post) => Post.fromJson(post))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: posts, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load category posts',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get all tags
  Future<ApiResponse<List<Tag>>> getTags() async {
    try {
      final url = ApiConfig.buildUrl(ApiConfig.tags);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final tags = (json['data'] as List)
              .map((tag) => Tag.fromJson(tag))
              .toList();

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: tags,
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load tags',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get menus
  Future<ApiResponse<List<Menu>>> getMenus() async {
    try {
      final url = ApiConfig.buildUrl(ApiConfig.menus);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final menus = (json['data'] as List)
              .map((menu) => Menu.fromJson(menu))
              .toList();

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: menus,
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load menus',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get media
  Future<ApiResponse<PaginatedResponse<Media>>> getMedia({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = {
        'page': page,
        'per_page': perPage,
      };

      final url = ApiConfig.buildUrl(ApiConfig.media, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final mediaList = (data['media'] as List)
              .map((media) => Media.fromJson(media))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: mediaList, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load media',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Search posts and pages
  Future<ApiResponse<PaginatedResponse<Post>>> search(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final params = {
        'search': query,
        'page': page,
        'per_page': perPage,
      };

      final url = ApiConfig.buildUrl(ApiConfig.search, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final results = (data['results'] as List)
              .map((post) => Post.fromJson(post))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: results, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to search',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get recent posts
  Future<ApiResponse<List<Post>>> getRecentPosts({int limit = 5}) async {
    try {
      final url = ApiConfig.buildUrl(
        ApiConfig.recentPosts,
        params: {'limit': limit},
      );
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final posts = (json['data'] as List)
              .map((post) => Post.fromJson(post))
              .toList();

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: posts,
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load recent posts',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get featured posts
  Future<ApiResponse<PaginatedResponse<Post>>> getFeaturedPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final params = {
        'page': page,
        'per_page': perPage,
      };

      final url = ApiConfig.buildUrl(ApiConfig.featuredPosts, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final posts = (data['posts'] as List)
              .map((post) => Post.fromJson(post))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: posts, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load featured posts',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // Get comments
  Future<ApiResponse<PaginatedResponse<Comment>>> getComments({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final params = {
        'page': page,
        'per_page': perPage,
      };

      final url = ApiConfig.buildUrl(ApiConfig.comments, params: params);
      final response = await http
          .get(Uri.parse(url))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final comments = (data['comments'] as List)
              .map((comment) => Comment.fromJson(comment))
              .toList();
          final pagination = Pagination.fromJson(data['pagination']);

          return ApiResponse(
            success: true,
            message: json['message'] ?? '',
            data: PaginatedResponse(items: comments, pagination: pagination),
            timestamp: json['timestamp'] ?? 0,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load comments',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }
}
