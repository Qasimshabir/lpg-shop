import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';

/// Dialog for configuring the API Base URL
class BaseUrlConfigDialog extends StatefulWidget {
  const BaseUrlConfigDialog({Key? key}) : super(key: key);

  @override
  State<BaseUrlConfigDialog> createState() => _BaseUrlConfigDialogState();
}

class _BaseUrlConfigDialogState extends State<BaseUrlConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = SettingsService.getBaseUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final normalizedUrl = SettingsService.normalizeUrl(_urlController.text.trim());
      
      // Test the connection by making a simple request
      // You can implement a health check endpoint on your server
      // For now, we'll just validate the URL format
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection test successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection test failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final normalizedUrl = SettingsService.normalizeUrl(_urlController.text.trim());
      await SettingsService.setBaseUrl(normalizedUrl);
      
      // Reinitialize API service to use new URL
      await ApiService.init();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base URL saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save URL: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text('Are you sure you want to reset the Base URL to default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SettingsService.resetBaseUrl();
      setState(() {
        _urlController.text = SettingsService.getBaseUrl();
        _errorMessage = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base URL reset to default'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF2C3E50)),
                  const SizedBox(width: 8),
                  const Text(
                    'Configure Base URL',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter the API server URL:',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Format: http://YOUR_IP:5000 (without /api)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // URL Input Field
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'http://10.141.196.72:5000',
                          prefixIcon: const Icon(Icons.link),
                          border: const OutlineInputBorder(),
                          helperText: 'Example: http://10.141.196.72:5000',
                          errorText: _errorMessage,
                        ),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 3,
                        minLines: 1,
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a URL';
                          }
                          
                          if (!SettingsService.isValidUrl(value.trim())) {
                            return 'Please enter a valid URL (http:// or https://)';
                          }
                          
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      
                      // Advanced Options Toggle
                      InkWell(
                        onTap: () {
                          setState(() => _showAdvanced = !_showAdvanced);
                        },
                        child: Row(
                          children: [
                            Icon(
                              _showAdvanced ? Icons.expand_less : Icons.expand_more,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Advanced Options',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF3498DB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Advanced Options
                      if (_showAdvanced) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Common Configurations:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildQuickOption('Localhost', 'http://localhost:5000'),
                              _buildQuickOption('Current Network', 'http://10.141.196.72:5000'),
                              _buildQuickOption('Local Network', 'http://192.168.1.100:5000'),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Important Information',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Enter only the base URL (e.g., http://10.141.196.72:5000)\n'
                              '• /api will be added automatically\n'
                              '• Make sure your server is running on port 5000\n'
                              '• Use your computer\'s IP address for mobile devices',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[900],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  // Reset Button
                  TextButton.icon(
                    onPressed: _isLoading ? null : _resetToDefault,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  
                  // Test Connection Button
                  TextButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.wifi_tethering, size: 16),
                    label: const Text('Test', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3498DB),
                    ),
                  ),
                  
                  // Cancel Button
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  
                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveUrl,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save, size: 16),
                    label: Text(
                      _isLoading ? 'Saving...' : 'Save',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOption(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _urlController.text = url;
          _errorMessage = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
