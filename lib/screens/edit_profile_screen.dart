import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;
  late TextEditingController _countryController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    _firstNameController = TextEditingController(text: widget.userData['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.userData['last_name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['billing']?['phone'] ?? '');
    _companyController = TextEditingController(text: widget.userData['billing']?['company'] ?? '');
    _address1Controller = TextEditingController(text: widget.userData['billing']?['address_1'] ?? '');
    _address2Controller = TextEditingController(text: widget.userData['billing']?['address_2'] ?? '');
    _cityController = TextEditingController(text: widget.userData['billing']?['city'] ?? '');
    _stateController = TextEditingController(text: widget.userData['billing']?['state'] ?? '');
    _postcodeController = TextEditingController(text: widget.userData['billing']?['postcode'] ?? '');
    _countryController = TextEditingController(text: widget.userData['billing']?['country'] ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updateData = {
      'company': _companyController.text.trim(),
      'address_1': _address1Controller.text.trim(),
      'address_2': _address2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'postcode': _postcodeController.text.trim(),
      'country': _countryController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    final success = await _authService.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      billing: updateData,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF79B2D5),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader('Personal Information', Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Billing Address Section
                    _buildSectionHeader('Billing Address', Icons.location_on),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _companyController,
                      label: 'Company (Optional)',
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _address1Controller,
                      label: 'Address Line 1',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _address2Controller,
                      label: 'Address Line 2 (Optional)',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _stateController,
                      label: 'State / Province',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _postcodeController,
                      label: 'Postcode / ZIP',
                      icon: Icons.markunread_mailbox_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      icon: Icons.flag_outlined,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button (for mobile view)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF79B2D5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF79B2D5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF79B2D5), size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF79B2D5),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF79B2D5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF79B2D5), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
