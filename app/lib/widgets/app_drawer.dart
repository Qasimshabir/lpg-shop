import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../lpg_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/feedback/feedback_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/dashboard',
                    onTap: () => _navigateTo(context, const DashboardScreen()),
                  ),
                  Divider(height: 1),
                  _buildSectionHeader('INVENTORY'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Products & Cylinders',
                    route: '/products',
                    onTap: () => _navigateTo(context, const ProductsScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.propane_tank,
                    title: 'Cylinder Tracking',
                    route: '/cylinders',
                    onTap: () => _showComingSoon(context, 'Cylinder Tracking'),
                  ),
                  Divider(height: 1),
                  _buildSectionHeader('OPERATIONS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.point_of_sale,
                    title: 'Sales',
                    route: '/sales',
                    onTap: () => _navigateTo(context, const SalesScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'Customers',
                    route: '/customers',
                    onTap: () => _navigateTo(context, const CustomersScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.local_shipping,
                    title: 'Delivery',
                    route: '/delivery',
                    onTap: () => _showComingSoon(context, 'Delivery Management'),
                  ),
                  Divider(height: 1),
                  _buildSectionHeader('ANALYTICS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics,
                    title: 'Reports',
                    route: '/reports',
                    onTap: () => _navigateTo(context, const ReportsScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.trending_up,
                    title: 'Business Insights',
                    route: '/insights',
                    onTap: () => _showComingSoon(context, 'Business Insights'),
                  ),
                  Divider(height: 1),
                  _buildSectionHeader('SAFETY & COMPLIANCE'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.security,
                    title: 'Safety Checklists',
                    route: '/safety',
                    onTap: () => _showComingSoon(context, 'Safety Checklists'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.warning,
                    title: 'Incidents',
                    route: '/incidents',
                    onTap: () => _showComingSoon(context, 'Incident Reports'),
                  ),
                  Divider(height: 1),
                  _buildSectionHeader('ACCOUNT'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.feedback,
                    title: 'Feedback',
                    route: '/feedback',
                    onTap: () => _navigateTo(context, const FeedbackScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: 'Profile',
                    route: '/profile',
                    onTap: () => _navigateTo(context, const ProfileScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    route: '/settings',
                    onTap: () => _showComingSoon(context, 'Settings'),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [LPGColors.primary, LPGColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.propane_tank,
              size: 40,
              color: LPGColors.secondary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'LPG Dealer',
            style: LPGTextStyles.heading3.copyWith(color: Colors.white),
          ),
          Text(
            'Management System',
            style: LPGTextStyles.body2.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: LPGTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: LPGColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? LPGColors.primary : LPGColors.textSecondary,
      ),
      title: Text(
        title,
        style: LPGTextStyles.body1.copyWith(
          color: isSelected ? LPGColors.primary : LPGColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: LPGColors.primary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout, color: LPGColors.error),
      title: Text(
        'Logout',
        style: LPGTextStyles.body1.copyWith(
          color: LPGColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _handleLogout(context),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: LPGColors.info,
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LPGColors.error,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
