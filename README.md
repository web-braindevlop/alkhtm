# Alkhatm - WordPress iOS App

A Flutter iOS application that connects to your WordPress website via custom REST API.

## Features

- ✅ View all posts with pagination
- ✅ View single post with comments
- ✅ View pages
- ✅ Browse categories and tags
- ✅ Search functionality
- ✅ View menus
- ✅ Media gallery
- ✅ WooCommerce integration ready
- ✅ Responsive UI
- ✅ Pull to refresh
- ✅ Infinite scroll

## Setup

### 1. Install Dependencies

Run the following command in the `alkhatm` directory:

```bash
flutter pub get
```

### 2. Configure API URL

Edit `lib/config/api_config.dart` and update the base URL:

```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS/wordpress';
```

**Note:** For iOS simulator testing:
- Use `http://localhost/wordpress` if testing on the same machine
- Use `http://YOUR_LOCAL_IP/wordpress` for physical device testing (e.g., `http://192.168.1.100/wordpress`)

### 3. WordPress Setup

Make sure your WordPress site has:
- The custom API bridge file: `wp-api-bridge.php` ✅ (Already created)
- WooCommerce installed (if using e-commerce features)
- Proper CORS headers ✅ (Already configured)

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API configuration and URLs
├── models/
│   ├── api_response.dart        # API response models
│   └── wordpress_models.dart    # WordPress data models
├── services/
│   └── wordpress_service.dart   # API service methods
├── screens/
│   └── home_screen.dart         # Example home screen
└── main.dart                    # App entry point
```

## Available Services

### WordPress Service (`wordpress_service.dart`)

```dart
// Get site info
final siteInfo = await WordPressService().getSiteInfo();

// Get posts with pagination
final posts = await WordPressService().getPosts(page: 1, perPage: 10);

// Get single post
final post = await WordPressService().getPost(postId);

// Get pages
final pages = await WordPressService().getPages();

// Get categories
final categories = await WordPressService().getCategories();

// Get posts by category
final categoryPosts = await WordPressService().getPostsByCategory(categoryId);

// Search
final results = await WordPressService().search('query');

// Get recent posts
final recent = await WordPressService().getRecentPosts(limit: 5);

// Get featured posts
final featured = await WordPressService().getFeaturedPosts();
```

## API Endpoints

All endpoints are documented in `API-DOCUMENTATION.md` in the WordPress root folder.

### Base URL
```
http://localhost/wordpress/wp-api-bridge.php
```

### Example Requests

```
# Get all posts
http://localhost/wordpress/wp-api-bridge.php?action=posts&page=1&per_page=10

# Get single post
http://localhost/wordpress/wp-api-bridge.php?action=post&id=1

# Search
http://localhost/wordpress/wp-api-bridge.php?action=search&search=hello

# Get categories
http://localhost/wordpress/wp-api-bridge.php?action=categories
```

## WooCommerce Integration

For WooCommerce features, use the native WooCommerce REST API:

```dart
// Base URL
http://localhost/wordpress/wp-json/wc/v3/

// Example: Get products
http://localhost/wordpress/wp-json/wc/v3/products?consumer_key=YOUR_KEY&consumer_secret=YOUR_SECRET
```

Your WooCommerce credentials:
- Consumer Key: `ck_f8654c6fd750b2b85e9b4afe97d6bd536b104377`
- Consumer Secret: `cs_f4b0460ef63f0ea5a3e44a51edb1ce90c18a524f`

## Testing

### Test the API

You can test the API endpoints using:

1. **Browser:** Visit the URLs directly
2. **Postman:** Import the API collection
3. **Flutter App:** Run the app and check the console logs

### Debug Mode

To enable debug mode, check the responses in your Flutter app:

```dart
final response = await WordPressService().getPosts();
print('Success: ${response.success}');
print('Message: ${response.message}');
print('Data: ${response.data}');
```

## Common Issues

### 1. Connection Error

If you get connection errors:
- Make sure XAMPP Apache is running
- Check if the API URL is correct
- For physical device, use your local IP address instead of `localhost`
- Ensure your device and computer are on the same network

### 2. CORS Error

If you encounter CORS issues:
- The `wp-api-bridge.php` file already includes CORS headers
- Make sure the file is in the WordPress root directory

### 3. Timeout Error

If requests timeout:
- Check `wp-config.php` for timeout settings (already configured)
- Ensure your internet connection is stable
- Increase timeout in `api_config.dart` if needed

## Next Steps

1. **Customize UI:** Design your app's unique interface
2. **Add Authentication:** Implement user login/registration
3. **Add WooCommerce:** Create product listings and shopping cart
4. **Add Push Notifications:** Integrate Firebase for notifications
5. **Offline Support:** Implement local caching with SQLite
6. **Add Comments:** Allow users to post comments
7. **Social Sharing:** Add share functionality

## Dependencies

The app uses the following Flutter packages:

- `http` - HTTP requests
- `provider` - State management
- `flutter_html` - HTML content rendering
- `cached_network_image` - Image caching
- `url_launcher` - Open external links
- `flutter_spinkit` - Loading animations
- `shared_preferences` - Local storage

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [WordPress REST API](https://developer.wordpress.org/rest-api/)
- [WooCommerce REST API](https://woocommerce.github.io/woocommerce-rest-api-docs/)
- [API Documentation](../API-DOCUMENTATION.md)

## Support

For issues or questions:
1. Check the API documentation
2. Test endpoints in browser
3. Check Flutter console for errors
4. Verify WordPress site is accessible
