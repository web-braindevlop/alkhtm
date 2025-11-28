import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Register new user
  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('user_register')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
        }),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Login user
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('user_login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data'];
        
        // Save user session
        await _saveUserSession(
          userId: userData['user_id'],
          token: userData['auth_token'],
          userData: userData,
        );
        
        // Merge guest cart if exists
        await _mergeGuestCart();
        
        return userData;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user session locally
  Future<void> _saveUserSession({
    required int userId,
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userIdKey) && prefs.containsKey(_tokenKey);
  }

  // Get current user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Fetch fresh user info from server
  Future<Map<String, dynamic>?> fetchUserInfo() async {
    try {
      final userId = await getUserId();
      final token = await getToken();
      
      if (userId == null || token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl('user_info', params: {
          'user_id': userId.toString(),
          'token': token,
        })),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data'];
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode(userData));
        
        return userData;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user orders
  Future<Map<String, dynamic>?> getUserOrders({int page = 1, int perPage = 20}) async {
    try {
      final userId = await getUserId();
      final token = await getToken();
      
      if (userId == null || token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl('user_orders', params: {
          'user_id': userId.toString(),
          'token': token,
          'page': page.toString(),
          'per_page': perPage.toString(),
        })),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    Map<String, String>? billing,
  }) async {
    try {
      final userId = await getUserId();
      final token = await getToken();
      
      if (userId == null || token == null) {
        return false;
      }

      final requestBody = {
        'user_id': userId,
        'token': token,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (billing != null) 'billing': billing,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('update_user_profile')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Save updated user data directly from response
        if (data['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userDataKey, jsonEncode(data['data']));
        }
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }

  // Merge guest cart with user cart (preserves cart on login/register)
  Future<void> _mergeGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');
      
      if (cartJson != null && cartJson != '[]') {
        // Guest cart exists and is preserved automatically
        // SharedPreferences 'cart' key is used for both guest and logged-in users
      }
    } catch (e) {
      // Silently handle any cart merge errors
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('reset_password_request')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Delete user account (Apple App Store requirement - Guideline 5.1.1(v))
  Future<bool> deleteAccount() async {
    try {
      final userId = await getUserId();
      final token = await getToken();
      
      if (userId == null || token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('delete_user_account')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': token,
        }),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Clear local session data after successful account deletion
        await logout();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}
