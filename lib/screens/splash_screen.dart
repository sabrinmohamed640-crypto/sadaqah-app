import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show firebaseInitialized;
import '../services/auth_service.dart';
import '../utils/app_roles.dart';
import 'admin_home_page.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers for smooth entrance effects
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _slideController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  // Timer reference so it can be cancelled on manual tap
  Timer? _navigationTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for the logo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Scale/pulse animation for the icon
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Slide-up animation for the text
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Trigger animations sequentially
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _slideController.forward();
    });

    // Navigate to next screen after exactly 2 seconds
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      _navigateToNext();
    });
  }

  // Shared navigation method — checks login status and routes
  void _navigateToNext() {
    if (_isNavigating) return;
    _navigationTimer?.cancel();
    if (mounted) {
      bool isLoggedIn = false;
      User? currentUser;
      if (firebaseInitialized) {
        try {
          currentUser = FirebaseAuth.instance.currentUser;
          isLoggedIn = currentUser != null;
        } catch (e) {
          debugPrint('Auth check error: $e');
        }
      }

      if (!firebaseInitialized) {
        _isNavigating = true;
        _performNavigation(const HomeScreen());
      } else if (isLoggedIn && currentUser != null) {
        _isNavigating = true;
        _navigateBasedOnRole(currentUser.uid);
      } else {
        _isNavigating = true;
        _performNavigation(const LoginScreen());
      }
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      final role = await AuthService().getUserRole(uid);
      if (AppRoles.isAdminRole(role)) {
        _performNavigation(const AdminHomePage());
      } else {
        _performNavigation(const HomeScreen());
      }
    } catch (e) {
      debugPrint('Error getting user role on splash: $e');
      _performNavigation(const HomeScreen());
    }
  }

  void _performNavigation(Widget nextScreen) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel(); // Ensure timer is cancelled if widget is disposed early
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Solid Dark Green background: 0xFF006400
        decoration: const BoxDecoration(
          color: Color(0xFF006400),
        ),
        child: GestureDetector(
          // Tapping anywhere navigates immediately and cancels the auto-timer
          onTap: _navigateToNext,
          behavior: HitTestBehavior.opaque,
          child: Stack(
          children: [
            // Decorative radial glow behind the icon
            Positioned(
              top: MediaQuery.of(context).size.height * 0.28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF34D399).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main content column
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Custom icon: stylized plant/sprout with coin/hand
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildZakatyIcon(),
                    ),
                    const SizedBox(height: 32),

                    // "KHAIRAT" brand text
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildBrandText(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Give. Grow. Purify.',
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 3.0,
                            color: Color(0xFFB2F5D8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading indicator dots at the bottom
            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    _PulsingDots(),
                    SizedBox(height: 16),
                    Text(
                      'نظام إدارة الزكاة والصدقات',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6EE7B7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // Custom container displaying the project logo from assets/logo.png
  Widget _buildZakatyIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.monetization_on_outlined,
            color: Colors.white,
            size: 60,
          );
        },
      ),
    );
  }

  Widget _buildBrandText() {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFD4AF37), // Warm gold
          Color(0xFFF0E080), // Light gold shimmer
          Color(0xFFD4AF37), // Warm gold
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: const Text(
        'KHAIRAT',
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          letterSpacing: 8.0,
          color: Colors.white, // overridden by ShaderMask
          height: 1.0,
        ),
      ),
    );
  }
}


// Subtle animated 3-dot loading indicator
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      _controllers.add(controller);
      _animations.add(animation);

      // Stagger each dot by 200ms
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) controller.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return FadeTransition(
          opacity: _animations[i],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6EE7B7),
            ),
          ),
        );
      }),
    );
  }
}
