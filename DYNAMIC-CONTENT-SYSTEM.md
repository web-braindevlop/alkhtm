# Dynamic Content System Implementation

## Overview
Your Flutter app now uses a **fully dynamic content system** that automatically synchronizes with your WordPress/WooCommerce website. This means you can update content on your website, and the changes will appear in the mobile app **without requiring an App Store update**.

## ✅ What's Now Dynamic

### 1. **Logo Images**
- **Dark Logo**: Main app logo (shown on dark backgrounds)
- **Light Logo**: Secondary logo
- **Location**: Appears in AppBar and Drawer

**How to Update:**
- Go to WordPress Admin → Appearance → Customize → Site Identity
- Upload a new Custom Logo
- Changes will appear in the app within 1 hour (cached) or immediately after pull-to-refresh

### 2. **Category Images**
- All product category images are now loaded from WordPress
- **Fallback system**: If a category doesn't have an image in WordPress, the app uses predefined fallback URLs

**How to Update:**
1. Go to WordPress Admin → Products → Categories
2. Edit any category
3. Upload/select a Thumbnail image
4. Save changes
5. The new image will appear in the app immediately after pull-to-refresh

**Set Category Images Using Script:**
- Run the provided `set-category-images.php` script to automatically map existing images to categories
- This only needs to be done once to populate all category thumbnails

### 3. **Country Flag Images**
- Emirates, Kuwait, Saudi Arabia flag images
- Displayed in the country flags section of the home page

**How to Update:**
- Replace the images in WordPress Media Library with the same filenames:
  - `EMARATI.png`
  - `KUWAITI.png`
  - `SAUDI-ARABIA.png`
- Changes will sync automatically after 1-hour cache expires or pull-to-refresh

### 4. **Products**
- Product names, prices, images, descriptions, variations, attributes
- **Auto-sync**: 24-hour cache + manual pull-to-refresh
- **Location**: Shop screen, Featured Products, Sale Products, Category pages

**How to Update:**
1. Go to WordPress Admin → Products
2. Add, edit, or delete products
3. Changes appear in app immediately after pull-to-refresh (or within 24 hours automatically)

### 5. **Featured Products Limit**
- Increased from 8 to 50 products
- Automatically displays all products marked as "Featured" in WooCommerce

**How to Feature Products:**
1. Edit any product in WordPress
2. Check the "Featured" checkbox in Product Data
3. Save
4. Product will appear in Featured Products section

### 6. **Sale Products**
- Increased limit from 8 to 50
- Automatically shows products with sale prices

### 7. **Product Variations & Attributes**
- Size, Color, and other attributes are dynamically loaded
- Color chips display actual colors from WordPress
- **No hardcoded values**

## 🔄 How Auto-Sync Works

### 24-Hour Cache System
1. When the app opens, it loads cached data **instantly** (no loading screen)
2. In the background, it checks WordPress for updates
3. If changes are found, the cache is updated
4. Cache expires after 24 hours automatically

### Manual Refresh
- Users can pull-to-refresh on any screen to force an immediate sync
- Useful when you make urgent updates to the website

### What Gets Synchronized:
- ✅ Site information (logos, name, URL)
- ✅ Products (all details, images, variations)
- ✅ Categories (names, images, counts)
- ✅ Featured products list
- ✅ Sale products list
- ✅ Product availability (in stock / out of stock)
- ✅ Prices (regular and sale prices)
- ✅ Product images (including variation images)

## 📡 Technical Details

### API Endpoint
**Site Info:** `https://alkhatm.com/wp-api-bridge.php?action=site_info`

Returns:
```json
{
  "success": true,
  "data": {
    "name": "Your Site Name",
    "url": "https://alkhatm.com",
    "assets": {
      "logo": "https://alkhatm.com/wp-content/uploads/.../logo.png",
      "logo_dark": "https://alkhatm.com/wp-content/uploads/.../logo-dark.png",
      "category_images": {
        "SANDALS": "https://alkhatm.com/wp-content/uploads/.../sandals.png",
        "AGAL": "https://alkhatm.com/wp-content/uploads/.../agal.png",
        // ... more categories
      },
      "country_flags": {
        "UAE": "https://alkhatm.com/wp-content/uploads/.../EMARATI.png",
        "KUWAIT": "https://alkhatm.com/wp-content/uploads/.../KUWAITI.png",
        "SAUDI": "https://alkhatm.com/wp-content/uploads/.../SAUDI-ARABIA.png"
      }
    }
  }
}
```

### Cache Expiration
- **Site Info**: 1 hour
- **Products**: 24 hours
- **Categories**: 24 hours
- **User can force refresh** by pull-to-refresh gesture

### Fallback System
If WordPress doesn't have an image set for a category or asset, the app uses predefined fallback URLs:
- Ensures the app always displays correctly
- Prevents broken images
- You can update these in WordPress at any time

## 🚀 Deployment Checklist

### Before Publishing to App Store:
- [ ] Upload `wp-api-bridge.php` to your live WordPress server
- [ ] Test the site_info endpoint: `https://alkhatm.com/wp-api-bridge.php?action=site_info`
- [ ] Set all category images in WordPress (or run `set-category-images.php`)
- [ ] Verify logo appears in Appearance → Customize → Site Identity
- [ ] Mark products as "Featured" that you want to highlight
- [ ] Add sale prices to products you want in Sale section
- [ ] Clear transient cache: `delete_transient('api_site_info');`

### After App Store Approval:
You can freely update:
- ✅ Product information
- ✅ Product images
- ✅ Category images
- ✅ Logos
- ✅ Prices
- ✅ Featured product selection
- ✅ Product variations

**NO APP STORE UPDATE NEEDED!** Changes sync automatically.

## 📝 Common Tasks

### Add a New Product
1. WordPress Admin → Products → Add New
2. Fill in product details
3. Add images
4. Set price
5. Check "Featured" if you want it highlighted
6. Publish
7. **App users will see it within 24 hours** (or immediately with pull-to-refresh)

### Change a Logo
1. WordPress Admin → Appearance → Customize → Site Identity
2. Upload new Custom Logo
3. Save
4. **App updates within 1 hour** (cached)

### Update Category Image
1. WordPress Admin → Products → Categories
2. Click Edit on the category
3. Upload Thumbnail
4. Save
5. **App updates immediately** after pull-to-refresh

### Mark Product as Featured
1. Edit product in WordPress
2. Product Data → Check "Featured product"
3. Save
4. **Appears in Featured Products section** after refresh

### Change Product Price
1. Edit product in WordPress
2. Update Regular Price or Sale Price
3. Save
4. **New price appears in app** within 24 hours or immediately with refresh

## 🛠️ Maintenance

### Clear WordPress Cache
If changes aren't appearing, clear the transient cache:
```php
delete_transient('api_site_info');
```

Or regenerate by visiting:
```
https://alkhatm.com/wp-api-bridge.php?action=site_info
```

### Check API Response
Test your API to see what data the app receives:
```
https://alkhatm.com/wp-api-bridge.php?action=site_info
https://alkhatm.com/wp-api-bridge.php?action=woo_categories&per_page=100
https://alkhatm.com/wp-api-bridge.php?action=woo_products&per_page=50&featured=true
```

### App Error Logs
The app console shows detailed logs about what data is loading:
- `📦 [CATEGORIES] Loaded X categories`
- `⭐ [FEATURED] Loaded X featured products`
- `🏷️ [SALE] Loaded X sale products`
- `🖼️ [CATEGORY] Category Name -> Image: URL (from WordPress or fallback)`

## 🎯 Benefits

### For You (Website Owner):
- **No App Store updates needed** for content changes
- Update products, prices, images anytime
- See changes in app immediately (or within 24 hours)
- Full control from WordPress admin panel

### For Users:
- Always see the latest products and prices
- Fast loading with instant cache
- Fresh data with pull-to-refresh
- Consistent experience with website

---

## Support

If you need to add more dynamic fields or have questions about the system:
1. Check `wp-api-bridge.php` for the API structure
2. Check `dynamic_home_screen.dart` for how the app uses dynamic data
3. All asset URLs are loaded from `_siteInfo.assets` instead of hardcoded values

The system is designed to be maintainable and scalable. Future enhancements can be added to the `assets` object in the site_info endpoint.
