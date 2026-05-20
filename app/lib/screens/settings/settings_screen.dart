import 'package:flutter/material.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/base_url_config_dialog.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _baseUrl = '';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final url = SettingsService.getBaseUrl();
    final language = SettingsService.getLanguage();
    final theme = SettingsService.getTheme();
    final notifications = SettingsService.getNotificationsEnabled();
    
    setState(() {
      _baseUrl = url;
      _selectedLanguage = language;
      _selectedTheme = theme;
      _notificationsEnabled = notifications;
      _isLoading = false;
    });
  }

  Future<void> _showBaseUrlDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BaseUrlConfigDialog(),
    );
    if (result == true) {
      _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      drawer: AppDrawer(currentRoute: '/settings'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildSection('Server Configuration'),
                _buildSettingTile(
                  icon: Icons.dns,
                  title: 'API Base URL',
                  subtitle: _baseUrl.isEmpty ? 'Using default URL' : _baseUrl,
                  onTap: _showBaseUrlDialog,
                ),
                SizedBox(height: 24),
                _buildSection('Application'),
                _buildSettingTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: _selectedLanguage,
                  onTap: _showLanguageDialog,
                ),
                _buildSettingTile(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: _selectedTheme,
                  onTap: _showThemeDialog,
                ),
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Enable push notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationsEnabled = value);
                    await SettingsService.setNotificationsEnabled(value);
                    _showSuccess('Notification settings updated');
                  },
                ),
                SizedBox(height: 24),
                _buildSection('Data & Privacy'),
                _buildSettingTile(
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  subtitle: 'Export your data',
                  onTap: _showBackupDialog,
                ),
                _buildSettingTile(
                  icon: Icons.delete_sweep,
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  onTap: _showClearCacheDialog,
                ),
                SizedBox(height: 24),
                _buildSection('About'),
                _buildSettingTile(
                  icon: Icons.info,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
                _buildSettingTile(
                  icon: Icons.description,
                  title: 'Terms & Conditions',
                  subtitle: 'Read our terms',
                  onTap: _showTermsDialog,
                ),
                _buildSettingTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: _showPrivacyDialog,
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: LPGTextStyles.subtitle1.copyWith(
          color: LPGColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LPGColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: LPGColors.primary),
        ),
        title: Text(title, style: LPGTextStyles.body1),
        subtitle: Text(subtitle, style: LPGTextStyles.caption),
        trailing: onTap != null ? Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LPGColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: LPGColors.primary),
        ),
        title: Text(title, style: LPGTextStyles.body1),
        subtitle: Text(subtitle, style: LPGTextStyles.caption),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = [
      {'code': 'English', 'name': 'English', 'native': 'English'},
      {'code': 'Hindi', 'name': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'Urdu', 'name': 'Urdu', 'native': 'اردو'},
      {'code': 'Punjabi', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Note: Language preference is saved but full translation is not yet implemented.',
              style: LPGTextStyles.caption.copyWith(
                color: LPGColors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            ...languages.map((lang) {
              return RadioListTile<String>(
                title: Text('${lang['name']} (${lang['native']})'),
                value: lang['code']!,
                groupValue: _selectedLanguage,
                onChanged: (value) async {
                  setState(() => _selectedLanguage = value!);
                  await SettingsService.setLanguage(value!);
                  Navigator.pop(context);
                  _showSuccess('Language preference saved: $value');
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    final themes = ['Light', 'Dark', 'System'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...themes.map((theme) {
              return RadioListTile<String>(
                title: Text(theme),
                subtitle: Text(
                  theme == 'System' ? 'Follow device theme' : '$theme mode',
                  style: LPGTextStyles.caption,
                ),
                value: theme,
                groupValue: _selectedTheme,
                onChanged: (value) async {
                  setState(() => _selectedTheme = value!);
                  await SettingsService.setTheme(value!);
                  Navigator.pop(context);
                  
                  // Show restart dialog
                  _showRestartDialog();
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: LPGColors.info),
            SizedBox(width: 8),
            Text('Restart Required'),
          ],
        ),
        content: Text(
          'Theme has been updated. Please restart the app to see the changes.\n\n'
          'Close the app completely and reopen it.',
          style: LPGTextStyles.body2,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup & Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Export your settings to keep a backup or transfer to another device.'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final settingsJson = await SettingsService.exportSettings();
                  Navigator.pop(context);
                  
                  // Show the exported data in a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Settings Exported'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          settingsJson,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                  
                  _showSuccess('Settings exported successfully. Copy the text to save it.');
                } catch (e) {
                  _showError('Failed to export settings: $e');
                }
              },
              icon: Icon(Icons.download),
              label: Text('Export Settings'),
            ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showImportDialog();
              },
              icon: Icon(Icons.upload),
              label: Text('Import Settings'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paste the exported settings JSON below:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Paste JSON here',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final success = await SettingsService.importSettings(controller.text);
                Navigator.pop(context);
                
                if (success) {
                  _showSuccess('Settings imported successfully');
                  _loadSettings();
                } else {
                  _showError('Failed to import settings');
                }
              } catch (e) {
                Navigator.pop(context);
                _showError('Invalid settings data: $e');
              }
            },
            child: Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Text(
            'Terms & Conditions\n\n'
            '1. Acceptance of Terms\n'
            'By using this LPG Management System, you agree to these terms.\n\n'
            '2. User Responsibilities\n'
            '- Maintain accurate records\n'
            '- Follow safety guidelines\n'
            '- Protect your account credentials\n\n'
            '3. Data Usage\n'
            'Your data is stored securely and used only for business operations.\n\n'
            '4. Liability\n'
            'The system is provided as-is. Users are responsible for compliance with local regulations.\n\n'
            '5. Updates\n'
            'Terms may be updated periodically. Continued use constitutes acceptance.',
            style: LPGTextStyles.body2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            '1. Information Collection\n'
            'We collect business data including customer information, sales records, and delivery details.\n\n'
            '2. Data Usage\n'
            '- Business operations and analytics\n'
            '- Customer service\n'
            '- Safety compliance\n\n'
            '3. Data Protection\n'
            'Your data is encrypted and stored securely on Supabase servers.\n\n'
            '4. Data Sharing\n'
            'We do not share your data with third parties without consent.\n\n'
            '5. Your Rights\n'
            'You can access, modify, or delete your data at any time.\n\n'
            '6. Contact\n'
            'For privacy concerns, contact your system administrator.',
            style: LPGTextStyles.body2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() async {
    // Get cache size first
    final cacheSize = await SettingsService.getCacheSize();
    final cacheSizeMB = (cacheSize / (1024 * 1024)).toStringAsFixed(2);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache'),
        content: Text(
          'Current cache size: $cacheSizeMB MB\n\n'
          'Are you sure you want to clear the app cache? This will free up storage space but may slow down the app temporarily.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(child: CircularProgressIndicator()),
              );
              
              final success = await SettingsService.clearCache();
              Navigator.pop(context); // Close loading
              
              if (success) {
                _showSuccess('Cache cleared successfully ($cacheSizeMB MB freed)');
              } else {
                _showError('Failed to clear cache');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: LPGColors.error),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LPGColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LPGColors.success,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LPGColors.info,
      ),
    );
  }
}
