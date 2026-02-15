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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final url = await SettingsService.getBaseUrl();
    setState(() {
      _baseUrl = url;
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
                  subtitle: 'English',
                  onTap: () => _showComingSoon('Language Settings'),
                ),
                _buildSettingTile(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: 'Light',
                  onTap: () => _showComingSoon('Theme Settings'),
                ),
                _buildSettingTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => _showComingSoon('Notification Settings'),
                ),
                SizedBox(height: 24),
                _buildSection('Data & Privacy'),
                _buildSettingTile(
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  subtitle: 'Manage your data backups',
                  onTap: () => _showComingSoon('Backup Settings'),
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
                  onTap: () => _showComingSoon('Terms & Conditions'),
                ),
                _buildSettingTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () => _showComingSoon('Privacy Policy'),
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache'),
        content: Text('Are you sure you want to clear the app cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: LPGColors.success,
                ),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: LPGColors.info,
      ),
    );
  }
}
