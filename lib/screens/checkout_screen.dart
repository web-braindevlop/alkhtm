import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/woocommerce_service.dart';

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
    if (!_formKey.currentState!.validate()) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Billing Details Section
            _buildSectionHeader('Billing Details'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name *',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name *',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _companyController,
              label: 'Company Name (optional)',
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _countryController,
              label: 'Country / Region *',
              enabled: false,
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _address1Controller,
              label: 'Street Address *',
              hint: 'House number and street name',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _address2Controller,
              label: 'Apartment, suite, unit, etc. (optional)',
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _cityController,
              label: 'Town / City *',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _stateController,
              label: 'State / County (optional)',
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _postcodeController,
              label: 'Postcode / ZIP (optional)',
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Phone *',
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _emailController,
              label: 'Email Address *',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (!value!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Order Notes
            _buildSectionHeader('Additional Information'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _orderNotesController,
              label: 'Order Notes (optional)',
              hint: 'Notes about your order, e.g. special notes for delivery',
              maxLines: 4,
            ),
            
            const SizedBox(height: 24),
            
            // Order Review
            _buildSectionHeader('Your Order'),
            const SizedBox(height: 16),
            
            _buildOrderReview(),
            
            const SizedBox(height: 24),
            
            // Payment Methods
            _buildSectionHeader('Payment'),
            const SizedBox(height: 16),
            
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
        ),
      ),
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
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
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
