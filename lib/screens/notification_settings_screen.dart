import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../services/apns_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _generalNotifications = true;
  bool _orderNotifications = true;
  bool _offerNotifications = true;
  bool _newProductNotifications = false;
  String? _fcmToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Only get token on iOS
    final token = defaultTargetPlatform == TargetPlatform.iOS 
        ? await APNsService.getDeviceToken() 
        : null;
    
    setState(() {
      _generalNotifications = prefs.getBool('notif_general') ?? true;
      _orderNotifications = prefs.getBool('notif_orders') ?? true;
      _offerNotifications = prefs.getBool('notif_offers') ?? true;
      _newProductNotifications = prefs.getBool('notif_new_products') ?? false;
      _fcmToken = token;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value, String topic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Note: APNs doesn't use topics like Firebase
    // You can implement server-side logic to filter notifications by user preferences
    
    setState(() {
      switch (key) {
        case 'notif_general':
          _generalNotifications = value;
          break;
        case 'notif_orders':
          _orderNotifications = value;
          break;
        case 'notif_offers':
          _offerNotifications = value;
          break;
        case 'notif_new_products':
          _newProductNotifications = value;
          break;
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Manage your notification preferences',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildNotificationTile(
                  title: 'General Notifications',
                  subtitle: 'Receive general updates and announcements',
                  value: _generalNotifications,
                  icon: Icons.notifications_active,
                  onChanged: (value) => _updateSetting('notif_general', value, 'general'),
                ),
                
                const Divider(),
                
                _buildNotificationTile(
                  title: 'Order Updates',
                  subtitle: 'Get notified about your order status',
                  value: _orderNotifications,
                  icon: Icons.shopping_bag,
                  onChanged: (value) => _updateSetting('notif_orders', value, 'orders'),
                ),
                
                const Divider(),
                
                _buildNotificationTile(
                  title: 'Special Offers',
                  subtitle: 'Receive notifications about deals and promotions',
                  value: _offerNotifications,
                  icon: Icons.local_offer,
                  onChanged: (value) => _updateSetting('notif_offers', value, 'offers'),
                ),
                
                const Divider(),
                
                _buildNotificationTile(
                  title: 'New Products',
                  subtitle: 'Be the first to know about new arrivals',
                  value: _newProductNotifications,
                  icon: Icons.new_releases,
                  onChanged: (value) => _updateSetting('notif_new_products', value, 'new_products'),
                ),
                
                const SizedBox(height: 32),
                
                if (_fcmToken != null) ...[
                  const Text(
                    'Device Token',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fcmToken!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            // Copy token to clipboard
                            Clipboard.setData(ClipboardData(text: _fcmToken!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Token copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This token is used for testing push notifications. Share it with your developer to send test notifications.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF79B2D5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF79B2D5),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF79B2D5),
      ),
    );
  }
}
