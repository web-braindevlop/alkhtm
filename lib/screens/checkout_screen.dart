import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  // Billing Details Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _countryController = TextEditingController(text: 'United Arab Emirates');
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _orderNotesController = TextEditingController();
  
  String _selectedPaymentMethod = 'cod'; // Cash on Delivery as default
  bool _isProcessing = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    print('🔍 CHECKOUT: Starting _loadUserData...');
    final isLoggedIn = await _authService.isLoggedIn();
    print('🔍 CHECKOUT: isLoggedIn = $isLoggedIn');
    
    if (isLoggedIn) {
      // Try to get last order data first for better pre-fill
      print('🔍 CHECKOUT: Fetching user orders...');
      final ordersData = await _authService.getUserOrders(page: 1, perPage: 1);
      print('🔍 CHECKOUT: ordersData = $ordersData');
      
      print('🔍 CHECKOUT: Fetching user info...');
      final userData = await _authService.fetchUserInfo();
      print('🔍 CHECKOUT: userData = $userData');
      
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          
          // Pre-fill from user data
          _firstNameController.text = userData?['first_name'] ?? '';
          _lastNameController.text = userData?['last_name'] ?? '';
          _emailController.text = userData?['email'] ?? '';
          _phoneController.text = userData?['phone'] ?? '';
          
          print('🔍 CHECKOUT: Basic info filled - Name: ${_firstNameController.text} ${_lastNameController.text}, Phone: ${_phoneController.text}, Email: ${_emailController.text}');
          
          // If user has previous orders, use billing from last order
          if (ordersData != null && ordersData['orders'] != null) {
            print('🔍 CHECKOUT: ordersData is not null, checking orders...');
            final orders = ordersData['orders'] as List;
            print('🔍 CHECKOUT: Number of orders: ${orders.length}');
            
            if (orders.isNotEmpty) {
              final lastOrder = orders[0];
              print('🔍 CHECKOUT: Last order data: $lastOrder');
              
              final billing = lastOrder['billing'];
              print('🔍 CHECKOUT: Billing data from last order: $billing');
              
              if (billing != null) {
                // Fill from last order, but only if fields are not empty
                _firstNameController.text = (billing['first_name']?.toString().trim().isNotEmpty ?? false) 
                    ? billing['first_name'] 
                    : _firstNameController.text;
                _lastNameController.text = (billing['last_name']?.toString().trim().isNotEmpty ?? false) 
                    ? billing['last_name'] 
                    : _lastNameController.text;
                _companyController.text = billing['company']?.toString().trim() ?? '';
                _address1Controller.text = billing['address_1']?.toString().trim() ?? '';
                _address2Controller.text = billing['address_2']?.toString().trim() ?? '';
                _cityController.text = billing['city']?.toString().trim() ?? '';
                _stateController.text = billing['state']?.toString().trim() ?? '';
                _postcodeController.text = billing['postcode']?.toString().trim() ?? '';
                _phoneController.text = (billing['phone']?.toString().trim().isNotEmpty ?? false) 
                    ? billing['phone'] 
                    : _phoneController.text;
                _emailController.text = (billing['email']?.toString().trim().isNotEmpty ?? false) 
                    ? billing['email'] 
                    : _emailController.text;
                
                print('✅ CHECKOUT: Billing fields filled from last order:');
                print('   Company: ${_companyController.text}');
                print('   Address 1: ${_address1Controller.text}');
                print('   Address 2: ${_address2Controller.text}');
                print('   City: ${_cityController.text}');
                print('   State: ${_stateController.text}');
                print('   Postcode: ${_postcodeController.text}');
              } else {
                print('⚠️ CHECKOUT: Billing data is NULL in last order');
              }
            } else {
              print('⚠️ CHECKOUT: Orders list is EMPTY');
            }
          } else {
            print('⚠️ CHECKOUT: ordersData is NULL or orders key is missing');
          }
          
          // Always check user profile for missing fields (fallback/supplement)
          print('🔍 CHECKOUT: Checking user profile for any missing billing data...');
          final profileBilling = userData?['billing'];
          print('🔍 CHECKOUT: User profile billing: $profileBilling');
          
          if (profileBilling != null) {
            // Fill empty fields from profile
            if (_companyController.text.isEmpty && profileBilling['company'] != null) {
              _companyController.text = profileBilling['company']?.toString().trim() ?? '';
            }
            if (_address1Controller.text.isEmpty && profileBilling['address_1'] != null) {
              _address1Controller.text = profileBilling['address_1']?.toString().trim() ?? '';
            }
            if (_address2Controller.text.isEmpty && profileBilling['address_2'] != null) {
              _address2Controller.text = profileBilling['address_2']?.toString().trim() ?? '';
            }
            if (_cityController.text.isEmpty && profileBilling['city'] != null) {
              _cityController.text = profileBilling['city']?.toString().trim() ?? '';
            }
            if (_stateController.text.isEmpty && profileBilling['state'] != null) {
              _stateController.text = profileBilling['state']?.toString().trim() ?? '';
            }
            if (_postcodeController.text.isEmpty && profileBilling['postcode'] != null) {
              _postcodeController.text = profileBilling['postcode']?.toString().trim() ?? '';
            }
            
            print('✅ CHECKOUT: Final billing fields (supplemented from profile):');
            print('   Company: ${_companyController.text}');
            print('   Address 1: ${_address1Controller.text}');
            print('   Address 2: ${_address2Controller.text}');
            print('   City: ${_cityController.text}');
            print('   State: ${_stateController.text}');
            print('   Postcode: ${_postcodeController.text}');
          } else {
            print('⚠️ CHECKOUT: No billing data in user profile');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _countryController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    // Force unfocus to trigger validation
    FocusScope.of(context).unfocus();
    
    // Additional manual validation for critical fields
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check if form is valid
    final isValid = _formKey.currentState?.validate() ?? false;
    
    if (!isValid) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields marked with *'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Scroll to top to show first error
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Prepare line items for WooCommerce
      final lineItems = widget.cartItems.map((item) {
        return {
          'product_id': item['id'],
          'quantity': item['quantity'],
        };
      }).toList();

      // Prepare billing information
      final billing = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'company': _companyController.text.trim(),
        'address_1': _address1Controller.text.trim(),
        'address_2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'country': 'AE', // UAE country code
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Get payment method title
      final paymentMethodTitle = _selectedPaymentMethod == 'cod' 
          ? 'Cash on Delivery' 
          : 'Direct Bank Transfer';

      // Create order via WooCommerce API
      final wooService = WooCommerceService();
      final orderResult = await wooService.createOrder(
        lineItems: lineItems,
        billing: billing,
        paymentMethod: _selectedPaymentMethod,
        paymentMethodTitle: paymentMethodTitle,
        customerNote: _orderNotesController.text.trim(),
      );

      if (orderResult != null && mounted) {
        // Order created successfully - clear cart
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cart', '[]');

        setState(() => _isProcessing = false);

        // Show success dialog with order details
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Order Placed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thank you for your order!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Order #${orderResult['order_number'] ?? orderResult['order_id']}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order Total: د.إ ${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${(orderResult['status'] ?? 'processing').toUpperCase()}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF79B2D5)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will receive a confirmation email shortly.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        // Order creation failed
        setState(() => _isProcessing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context) || ResponsiveUtils.isDesktop(context);
    final spacing = ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: isTablet ? _buildTabletLayout(spacing) : _buildMobileLayout(spacing),
      ),
    );
  }

  Widget _buildMobileLayout(double spacing) {
    return ListView(
      padding: ResponsiveUtils.getScreenPadding(context),
      children: [
        // Billing Details Section
        _buildSectionHeader('Billing Details'),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _companyController,
          label: 'Company Name (optional)',
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _countryController,
          label: 'Country / Region *',
          enabled: false,
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _address1Controller,
          label: 'Street Address *',
          hint: 'House number and street name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Street address is required';
            }
            return null;
          },
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _address2Controller,
          label: 'Apartment, suite, unit, etc. (optional)',
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _cityController,
          label: 'Town / City *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'City is required';
            }
            return null;
          },
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _stateController,
          label: 'State / County (optional)',
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _postcodeController,
          label: 'Postcode / ZIP (optional)',
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _phoneController,
          label: 'Phone *',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _emailController,
          label: 'Email Address *',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email address is required';
            }
            if (!value.trim().contains('@') || !value.trim().contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        
        SizedBox(height: spacing * 2),
        
        // Order Notes
        _buildSectionHeader('Additional Information'),
        SizedBox(height: spacing),
        
        _buildTextField(
          controller: _orderNotesController,
          label: 'Order Notes (optional)',
          hint: 'Notes about your order, e.g. special notes for delivery',
          maxLines: 4,
        ),
        
        SizedBox(height: spacing * 2),
        
        // Order Review
        _buildSectionHeader('Your Order'),
        SizedBox(height: spacing),
        
        _buildOrderReview(),
        
        SizedBox(height: spacing * 2),
        
        // Payment Methods
        _buildSectionHeader('Payment'),
        SizedBox(height: spacing),
        
        _buildPaymentMethods(),
        
        const SizedBox(height: 32),
        
        // Place Order Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF79B2D5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTabletLayout(double spacing) {
    return ListView(
      padding: ResponsiveUtils.getScreenPadding(context),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Billing Form
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Billing Details'),
                  SizedBox(height: spacing),
                  _buildSectionHeader('Billing Details'),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name *',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name *',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _companyController,
                    label: 'Company Name (optional)',
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _countryController,
                    label: 'Country / Region *',
                    enabled: false,
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _address1Controller,
                    label: 'Street Address *',
                    hint: 'House number and street name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Street address is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _address2Controller,
                    label: 'Apartment, suite, unit, etc. (optional)',
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _cityController,
                    label: 'Town / City *',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _stateController,
                    label: 'State / County (optional)',
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _postcodeController,
                    label: 'Postcode / ZIP (optional)',
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone *',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address *',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email address is required';
                      }
                      if (!value.trim().contains('@') || !value.trim().contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing * 2),
                  _buildSectionHeader('Additional Information'),
                  SizedBox(height: spacing),
                  _buildTextField(
                    controller: _orderNotesController,
                    label: 'Order Notes (optional)',
                    hint: 'Notes about your order, e.g. special notes for delivery',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing * 2),
            // Right Column: Order Summary
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Your Order'),
                  SizedBox(height: spacing),
                  _buildOrderReview(),
                  SizedBox(height: spacing * 2),
                  _buildSectionHeader('Payment'),
                  SizedBox(height: spacing),
                  _buildPaymentMethods(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF79B2D5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1a1a1a),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildOrderReview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Product Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Product',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Text(
                'Subtotal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Cart Items
          ...widget.cartItems.map((item) {
            final price = double.tryParse(item['price'].toString()) ?? 0.0;
            final quantity = item['quantity'] as int;
            final subtotal = price * quantity;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item['name']} × $quantity',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    'د.إ ${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const Divider(height: 24),
          
          // Subtotal
          _buildOrderRow('Subtotal', widget.total),
          const SizedBox(height: 8),
          
          // Shipping (Free for now)
          _buildOrderRow('Shipping', 0.0, subtext: 'Free Shipping'),
          
          const Divider(height: 24),
          
          // Total
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'د.إ ${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF79B2D5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String label, double amount, {String? subtext}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
              if (subtext != null)
                Text(
                  subtext,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        Text(
          'د.إ ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'cod',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            title: const Text(
              'Cash on Delivery',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Pay with cash upon delivery',
              style: TextStyle(fontSize: 12),
            ),
            activeColor: const Color(0xFF79B2D5),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          RadioListTile<String>(
            value: 'bank',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            title: const Text(
              'Direct Bank Transfer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Make your payment directly into our bank account',
              style: TextStyle(fontSize: 12),
            ),
            activeColor: const Color(0xFF79B2D5),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
