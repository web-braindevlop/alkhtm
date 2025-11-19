class ApiConfig {
  // WordPress API Base URLs
  static const String baseUrl = 'https://alkhatm.com';
  static const String apiUrl = '$baseUrl/wp-api-bridge.php';
  
  // WooCommerce API
  static const String wooCommerceUrl = 'https://alkhatm.com/wp-json/wc/v3';
  static const String consumerKey = 'ck_f8654c6fd750b2b85e9b4afe97d6bd536b104377';
  static const String consumerSecret = 'cs_f4b0460ef63f0ea5a3e44a51edb1ce90c18a524f';
  
  // API Actions
  static const String siteInfo = 'site_info';
  static const String posts = 'posts';
  static const String post = 'post';
  static const String pages = 'pages';
  static const String page = 'page';
  static const String categories = 'categories';
  static const String categoryPosts = 'category_posts';
  static const String tags = 'tags';
  static const String menus = 'menus';
  static const String media = 'media';
  static const String search = 'search';
  static const String recentPosts = 'recent_posts';
  static const String featuredPosts = 'featured_posts';
  static const String comments = 'comments';
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Build URL with action
  static String buildUrl(String action, {Map<String, dynamic>? params}) {
    final uri = Uri.parse(apiUrl).replace(queryParameters: {
      'action': action,
      ...?params?.map((key, value) => MapEntry(key, value.toString())),
    });
    return uri.toString();
  }
  
  // Build WooCommerce URL
  static String buildWooUrl(String endpoint, {Map<String, dynamic>? params}) {
    final uri = Uri.parse('$wooCommerceUrl/$endpoint').replace(queryParameters: {
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
      ...?params?.map((key, value) => MapEntry(key, value.toString())),
    });
    return uri.toString();
  }
}
