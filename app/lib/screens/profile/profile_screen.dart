import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _address = '';
  String _shopName = '';
  String _ownerName = '';
  String _city = '';
  String? _avatarBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);
    try {
      final loadedUser = await ApiService.getProfile();
      setState(() {
        user = loadedUser;
        _name = loadedUser.name;
        _phone = loadedUser.phone ?? '';
        _address = loadedUser.address ?? '';
        _shopName = loadedUser.shopName ?? '';
        _ownerName = loadedUser.ownerName ?? '';
        _city = loadedUser.city ?? '';
        _avatarBase64 = loadedUser.avatar;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load profile: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    try {
      await ApiService.updateProfile(
        name: _name,
        shopName: _shopName.isEmpty ? null : _shopName,
        ownerName: _ownerName.isEmpty ? null : _ownerName,
        city: _city.isEmpty ? null : _city,
        phone: _phone.isEmpty ? null : _phone,
        address: _address.isEmpty ? null : _address,
        avatar: _avatarBase64,
      );
      _showSuccessSnackBar('Profile updated successfully');
      _loadUserProfile(); // Reload profile
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _avatarBase64 = 'data:image/jpeg;base64,$base64String';
        });
        
        _showSuccessSnackBar('Profile picture updated. Remember to save changes!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }


  Future<void> _deleteProfile() async {
    final TextEditingController passwordController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your profile? This action cannot be undone.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Enter your password to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  _showErrorSnackBar('Please enter your password');
                  return;
                }
                
                try {
                  await ApiService.deleteProfile(passwordController.text);
                  
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Profile deleted successfully.');
                  
                  // Navigate to login screen
                  await ApiService.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  _showErrorSnackBar('Failed to delete profile: ${e.toString().replaceAll('Exception: ', '')}');
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Profile'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ApiService.logout();
                  
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  _showErrorSnackBar('Failed to logout: ${e.toString()}');
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Management'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete_profile':
                  _deleteProfile();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'delete_profile',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Profile', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : user == null
        ? const Center(child: Text('Failed to load profile'))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF2C3E50),
                                backgroundImage: _avatarBase64 != null
                                    ? MemoryImage(
                                        base64Decode(_avatarBase64!.split(',')[1]),
                                      )
                                    : null,
                                child: _avatarBase64 == null
                                    ? Text(
                                        user!.name.isNotEmpty ? user!.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE67E22),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user!.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            user!.shopName,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Edit Profile Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          onSaved: (value) => _name = value!,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: _shopName,
                          decoration: const InputDecoration(
                            labelText: 'Shop Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter shop name';
                            }
                            return null;
                          },
                          onSaved: (value) => _shopName = value!,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: _ownerName,
                          decoration: const InputDecoration(
                            labelText: 'Owner Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter owner name';
                            }
                            return null;
                          },
                          onSaved: (value) => _ownerName = value!,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: _city,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter city';
                            }
                            return null;
                          },
                          onSaved: (value) => _city = value!,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            hintText: 'e.g., +923001234567',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number is required';
                            }
                            final phoneRegex = RegExp(r'^(\+92|0)3\d{9}$');
                            if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
                              return 'Please enter a valid Pakistani phone number';
                            }
                            return null;
                          },
                          onSaved: (value) => _phone = value ?? '',
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: _address,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          onSaved: (value) => _address = value ?? '',
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C3E50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Update Profile',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
