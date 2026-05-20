import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lpg_theme.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'services/lpg_api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/lpg/lpg_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Settings service (must be before API service)
  await SettingsService.init();
  
  // Initialize API service
  await ApiService.init();
  
  runApp(const LPGDealerApp());
}

class LPGDealerApp extends StatefulWidget {
  const LPGDealerApp({super.key});

  @override
  State<LPGDealerApp> createState() => _LPGDealerAppState();
}

class _LPGDealerAppState extends State<LPGDealerApp> {
  String _currentTheme = 'Light';
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _currentTheme = SettingsService.getTheme();
      _currentLanguage = SettingsService.getLanguage();
    });
  }

  ThemeData _getThemeData() {
    switch (_currentTheme) {
      case 'Dark':
        return lpgTheme().copyWith(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF121212),
          cardTheme: CardThemeData(
            color: Color(0xFF1E1E1E),
            shadowColor: Colors.black.withOpacity(0.3),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        );
      case 'System':
        // Use system theme
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? _getThemeData() : lpgTheme();
      default:
        return lpgTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LPG Dealer Management System',
      theme: _getThemeData(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      // Add a way to rebuild the app when settings change
      builder: (context, child) {
        return child ?? SizedBox.shrink();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
    
    if (mounted) {
      if (ApiService.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LPGDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // LPG Blue
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.1,
                vertical: isLandscape ? 20 : 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated LPG Cylinder Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.propane_tank,
                          size: isLandscape ? 60 : 80,
                          color: Color.lerp(
                            const Color(0xFF1565C0), 
                            const Color(0xFFFF6F00), 
                            value,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isLandscape ? 16 : 24),
                  
                  // Main Title with Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Text(
                            'LPG DEALER\nManagement System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isLandscape ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isLandscape ? 8 : 12),
                  
                  // Subtitle
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1400),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          'Cylinders • Accessories • Sales • Delivery',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isLandscape ? 12 : 14,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isLandscape ? 20 : 32),
                  
                  // Loading Indicator with Fade Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
                          strokeWidth: 3,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
