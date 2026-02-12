# Variable Products Implementation Guide

## Overview
This guide explains how to implement variable products (products with variations like Size, Color, etc.) in your Flutter WooCommerce app.

## What Has Been Done

### 1. WordPress API Bridge Updates ✅
**File**: `wp-api-bridge.php`

The API now returns complete variation data for variable products:
- **Variations array**: All available variations with prices, stock, attributes
- **Attributes array**: Product attributes (Size, Color, etc.) with their options
- **Product type**: Identifies if product is 'simple' or 'variable'

**Example API Response for Variable Product:**
```json
{
  "id": 123,
  "name": "T-Shirt",
  "type": "variable",
  "price": "25.00",
  "variations": [
    {
      "id": 124,
      "price": "25.00",
      "attributes": {
        "attribute_pa_size": "small",
        "attribute_pa_color": "red"
      },
      "in_stock": true
    },
    {
      "id": 125,
      "price": "27.00",
      "attributes": {
        "attribute_pa_size": "large",
        "attribute_pa_color": "blue"
      },
      "in_stock": true
    }
  ],
  "attributes": [
    {
      "name": "Size",
      "slug": "pa_size",
      "options": [
        {"slug": "small", "name": "Small"},
        {"slug": "medium", "name": "Medium"},
        {"slug": "large", "name": "Large"}
      ]
    },
    {
      "name": "Color",
      "slug": "pa_color",
      "options": [
        {"slug": "red", "name": "Red"},
        {"slug": "blue", "name": "Blue"}
      ]
    }
  ]
}
```

### 2. Flutter Product Model Updates ✅
**File**: `alkhatm/lib/services/woocommerce_service.dart`

Added new classes:
- `ProductVariation`: Stores variation data (ID, price, attributes, stock)
- `ProductAttribute`: Stores attribute information (name, options)
- `AttributeOption`: Individual attribute option (slug, name)

Updated `WooProduct` class:
- Added `type` field (simple/variable)
- Added `variations` list
- Added `attributes` list
- Added `isVariable` getter

## What You Need to Implement

### 3. Product Detail Screen UI Updates
**File**: `alkhatm/lib/screens/product_detail_screen.dart`

You need to add variation selection UI in the product detail screen.

#### Step 3.1: Add State Variables
Add these to `_ProductDetailScreenState`:

```dart
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // ... existing variables ...
  
  // NEW: Variation selection
  Map<String, String> _selectedAttributes = {};
  ProductVariation? _selectedVariation;
  String _currentPrice = '';
  bool _variationInStock = true;
```

#### Step 3.2: Initialize for Variable Products
In `_loadProduct()` method, after setting `_product`:

```dart
Future<void> _loadProduct() async {
  // ... existing code ...
  
  if (!mounted) return;
  setState(() {
    _product = product;
    _isLoading = false;
    
    // NEW: Initialize for variable products
    if (product != null && product.isVariable) {
      _currentPrice = product.price;
      // Set default selection to first available variation
      if (product.variations.isNotEmpty) {
        final firstVariation = product.variations.first;
        _selectedVariation = firstVariation;
        _selectedAttributes = Map.from(firstVariation.attributes);
        _currentPrice = firstVariation.price;
        _variationInStock = firstVariation.inStock;
      }
    } else if (product != null) {
      _currentPrice = product.price;
      _variationInStock = product.inStock;
    }
  });
  
  // ... rest of code ...
}
```

#### Step 3.3: Add Variation Selection Method
Add this method to find matching variation:

```dart
void _updateSelectedVariation() {
  if (_product == null || !_product!.isVariable) return;
  
  // Find matching variation based on selected attributes
  for (var variation in _product!.variations) {
    bool matches = true;
    
    // Check if all selected attributes match this variation
    for (var entry in _selectedAttributes.entries) {
      final variationValue = variation.getAttributeValue(entry.key);
      if (variationValue != entry.value) {
        matches = false;
        break;
      }
    }
    
    if (matches) {
      setState(() {
        _selectedVariation = variation;
        _currentPrice = variation.price;
        _variationInStock = variation.inStock;
      });
      return;
    }
  }
  
  // No matching variation found
  setState(() {
    _selectedVariation = null;
    _variationInStock = false;
  });
}
```

#### Step 3.4: Add Variation Selector Widget
Insert this widget AFTER the product images and price section, BEFORE the description:

```dart
Widget _buildVariationSelector() {
  if (_product == null || !_product!.isVariable || _product!.attributes.isEmpty) {
    return const SizedBox.shrink();
  }
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Options:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Loop through each attribute (Size, Color, etc.)
        ...\_product!.attributes.map((attribute) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attribute.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Options as chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: attribute.options.map((option) {
                    final attributeKey = 'attribute_${attribute.slug}';
                    final isSelected = _selectedAttributes[attributeKey] == option.slug;
                    
                    return ChoiceChip(
                      label: Text(option.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedAttributes[attributeKey] = option.slug;
                          });
                          _updateSelectedVariation();
                        }
                      },
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
        
        // Show selected variation info
        if (_selectedVariation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _variationInStock ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _variationInStock ? Icons.check_circle : Icons.cancel,
                  color: _variationInStock ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _variationInStock 
                        ? 'In Stock - $_currentPrice' 
                        : 'Out of Stock',
                    style: TextStyle(
                      color: _variationInStock ? Colors.green[900] : Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_product!.variations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.orange[900],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select all options',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
```

#### Step 3.5: Update Price Display
Replace the price display section to use `_currentPrice`:

```dart
// OLD:
Text(
  _product!.price,
  style: const TextStyle(fontSize: 28),
),

// NEW:
Text(
  _currentPrice.isNotEmpty ? _currentPrice : _product!.price,
  style: const TextStyle(fontSize: 28),
),
```

#### Step 3.6: Update Add to Cart Button
Modify the "Add to Cart" button to disable if variation not selected:

```dart
ElevatedButton.icon(
  onPressed: (_product!.isVariable 
      ? (_variationInStock && _selectedVariation != null)
      : _product!.inStock)
    ? () async {
        await _addToCart();
        // ... existing code ...
      }
    : null,
  icon: const Icon(Icons.shopping_cart),
  label: Text(_product!.isVariable && _selectedVariation == null 
      ? 'Select Options' 
      : 'Add to Cart'),
  // ... existing styling ...
),
```

### 4. Cart System Updates
**File**: `alkhatm/lib/screens/product_detail_screen.dart`

Update the `_addToCart()` method to store variation information:

```dart
Future<void> _addToCart() async {
  if (_product == null) return;
  
  // For variable products, require a selected variation
  if (_product!.isVariable && _selectedVariation == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select product options'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final cartJson = prefs.getString('cart') ?? '[]';
  final List<dynamic> cart = json.decode(cartJson);

  // Create cart item
  final cartItem = {
    'id': _product!.isVariable ? _selectedVariation!.id : _product!.id,
    'product_id': _product!.id, // Store parent product ID
    'name': _product!.name,
    'price': _product!.isVariable ? _selectedVariation!.price : _product!.price,
    'image': _product!.images.isNotEmpty ? _product!.images.first.src : '',
    'quantity': 1,
  };
  
  // Add variation details if applicable
  if (_product!.isVariable && _selectedVariation != null) {
    cartItem['is_variation'] = true;
    cartItem['variation_id'] = _selectedVariation!.id;
    cartItem['variation_attributes'] = _selectedAttributes;
    
    // Add readable variation description
    final attributeNames = _selectedAttributes.entries.map((e) {
      final attrName = e.key.replaceAll('attribute_pa_', '').replaceAll('attribute_', '');
      return '$attrName: ${e.value}';
    }).join(', ');
    cartItem['variation_description'] = attributeNames;
  }

  // Check if same variation already exists in cart
  final existingIndex = cart.indexWhere((item) {
    if (_product!.isVariable) {
      return item['variation_id'] == _selectedVariation!.id;
    } else {
      return item['id'] == _product!.id && item['is_variation'] != true;
    }
  });

  if (existingIndex >= 0) {
    // Increment quantity
    cart[existingIndex]['quantity'] = (cart[existingIndex]['quantity'] as int) + 1;
  } else {
    // Add new item
    cart.add(cartItem);
  }

  await prefs.setString('cart', json.encode(cart));
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
```

### 5. Update Cart Display (Optional but Recommended)
**File**: `alkhatm/lib/screens/cart_screen.dart` (or wherever you display cart items)

When displaying cart items, show variation information:

```dart
// In your cart item widget:
Text(
  item['name'],
  style: const TextStyle(fontWeight: FontWeight.bold),
),
// Add variation info if it exists
if (item['variation_description'] != null) 
  Text(
    item['variation_description'],
    style: TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    ),
  ),
```

## Testing Variable Products

### 1. Create a Variable Product in WordPress
1. Go to WordPress Admin → Products → Add New
2. Enter product name (e.g., "T-Shirt")
3. Select "Variable product" from Product Data dropdown
4. Go to "Attributes" tab:
   - Click "Add"
   - Name: "Size"
   - Values: Small | Medium | Large
   - Check "Used for variations"
   - Save attributes
5. Go to "Variations" tab:
   - Select "Create variations from all attributes"
   - Click "Go"
   - Set prices for each variation
   - Ensure stock status is "In stock"
6. Publish the product

### 2. Test in Your App
1. Open the app and navigate to the variable product
2. You should see:
   - Attribute selectors (Size, Color, etc.)
   - Price updates when selecting variations
   - "Add to Cart" button enables when all options selected
3. Add to cart and verify:
   - Correct variation is added
   - Cart shows variation details
   - Different variations are treated as separate items

## Common Issues & Solutions

### Issue 1: Variations Not Showing
**Solution**: Ensure in WordPress:
- Product type is set to "Variable product"
- Attributes have "Used for variations" checked
- Variations are generated and have prices/stock

### Issue 2: Price Not Updating
**Solution**: Check that:
- `_updateSelectedVariation()` is called after attribute selection
- `_currentPrice` is being used in price display widget
- Variations have proper price values in WordPress

### Issue 3: Can't Add to Cart
**Solution**: Verify:
- All attributes are selected before allowing add to cart
- Selected variation is in stock
- `_selectedVariation` is not null for variable products

## Additional Features You Can Add

### 1. Show Variation Images
If variations have specific images, update the image selector to show variation images when selected.

### 2. Out of Stock Variations
Disable or visually indicate out-of-stock attribute combinations.

### 3. Price Range Display
For variable products, show price range on product list:
```dart
"From ${product.variations.map((v) => double.parse(v.price)).reduce(min)}"
```

### 4. Variation-Specific Descriptions
Show different descriptions for different variations if needed.

## Need Help?

If you encounter any issues:
1. Check that WordPress WooCommerce is properly configured
2. Verify API is returning variation data (test in browser: http://localhost/wordpress/wp-api-bridge.php?action=woo_product&id=YOUR_PRODUCT_ID)
3. Check Flutter console for any error messages
4. Ensure all new model classes are properly imported

---

## Summary of Files Modified

✅ **WordPress Backend:**
- `wp-api-bridge.php` - Updated to return variation and attribute data

✅ **Flutter App:**
- `alkhatm/lib/services/woocommerce_service.dart` - Added ProductVariation, ProductAttribute, AttributeOption classes

🔧 **Files YOU Need to Update:**
- `alkhatm/lib/screens/product_detail_screen.dart` - Add variation selector UI and update cart logic
- `alkhatm/lib/screens/cart_screen.dart` - Show variation info in cart (optional)

---

**Good luck with your implementation! Variable products will greatly enhance your WooCommerce app's functionality.** 🎉
