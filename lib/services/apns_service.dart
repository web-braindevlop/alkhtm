import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class APNsService {
  static const platform = MethodChannel('com.alkhatm.app/apns');
  static String? _deviceToken;
  
  /// Initialize APNs and set up listeners
  static Future<void> initialize() async {
    try {
      // Set up method call handler for receiving messages from native iOS
      platform.setMethodCallHandler(_handleMethod);
      
      print('✅ APNs Service initialized');
    } catch (e) {
      print('❌ Failed to initialize APNs: $e');
    }
  }
  
  /// Handle method calls from native iOS code
  static Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onTokenReceived':
        final token = call.arguments as String;
        await _handleTokenReceived(token);
        break;
      case 'onNotificationTapped':
        final data = call.arguments as Map<dynamic, dynamic>;
        _handleNotificationTapped(data);
        break;
      default:
        print('Unknown method: ${call.method}');
    }
  }
  
  /// Handle device token received from APNs
  static Future<void> _handleTokenReceived(String token) async {
    print('📱 APNs Device Token received: $token');
    _deviceToken = token;
    
    // Save token locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apns_device_token', token);
    
    // Send token to your backend server
    await _sendTokenToBackend(token);
  }
  
  /// Handle notification tap
  static void _handleNotificationTapped(Map<dynamic, dynamic> data) {
    print('👆 Notification tapped with data: $data');
    
    // Handle navigation based on notification data
    // You can use a navigator key or event bus to navigate
    
    // Example: Check if notification contains order_id
    if (data.containsKey('order_id')) {
      final orderId = data['order_id'];
      print('Navigate to order: $orderId');
      // TODO: Navigate to order details screen
    }
  }
  
  /// Send device token to your backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('⚠️ User not logged in, token will be sent after login');
        return;
      }
      
      // TODO: Replace with your actual backend endpoint
      final response = await http.post(
        Uri.parse('https://alkhatm.com/wordpress/wp-api-bridge.php?action=register_apns_token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'device_token': token,
          'platform': 'ios',
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Device token registered with backend');
      } else {
        print('❌ Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }
  
  /// Get the current device token
  static Future<String?> getDeviceToken() async {
    if (_deviceToken != null) return _deviceToken;
    
    final prefs = await SharedPreferences.getInstance();
    _deviceToken = prefs.getString('apns_device_token');
    return _deviceToken;
  }
  
  /// Request notification permissions (iOS will show permission dialog)
  static Future<bool> requestPermissions() async {
    try {
      // The permission is requested automatically in AppDelegate
      // This method is here for consistency
      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }
}
