import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../navigation/presentation/screens/main_navigation_screen.dart';
import 'register_screen.dart';
import 'category_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = isBn ? 'ইউজারনেম অথবা ইমেইল দেওয়া আবশ্যিক' : 'Username or Email is required');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = isBn ? 'পাসওয়ার্ড প্রদান করা আবশ্যিক' : 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = isBn ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' : 'Password must contain at least 6 characters');
      hasError = true;
    }

    if (hasError) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password, role: 'PATIENT');

    if (!mounted) return;

    if (success) {
      // Returning user login skips Category Selection and goes directly to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      final err = (authProvider.errorMessage ?? '').toLowerCase();
      setState(() {
        if (err.contains('password') || err.contains('credential') || err.contains('invalid')) {
          _passwordError = isBn ? 'পাসওয়ার্ডটি ভুল হয়েছে! আবার চেষ্টা করুন' : 'Incorrect password! Please try again';
          _emailError = isBn ? 'ইউজারনেম বা ইমেইল সঠিক নয়' : 'Check username or email';
        } else if (err.contains('user') || err.contains('email') || err.contains('not found')) {
          _emailError = isBn ? 'ইমেইল বা ইউজারনেম সঠিক নয়' : 'Incorrect username or email address';
        } else {
          _emailError = isBn ? 'ভুল ইমেইল বা ইউজারনেম' : 'Wrong username or email';
          _passwordError = isBn ? 'ভুল পাসওয়ার্ড' : 'Wrong password';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn
                ? 'লগইন তথ্য ভুল দেওয়া হয়েছে! লাল চিহ্নিত ফিল্ডে দেখুন।'
                : 'Incorrect credentials! Please check the highlighted red fields.',
          ),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.loginWithGoogle();

    if (!mounted) return;

    if (result['success'] == true) {
      final bool isNewUser = result['isNewUser'] ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'গুগল অ্যাকাউন্ট দিয়ে সফলভাবে অ্যাকাউন্ট সংযুক্ত হয়েছে!' : 'Signed in with Google successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (isNewUser) {
        // First-time registered Google user -> Category Selection Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
        );
      } else {
        // Returning Google user -> Main Navigation Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } else if (result['cancelled'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? (isBn ? 'গুগল সাইন-ইন ব্যর্থ হয়েছে।' : 'Google Sign-In failed.')),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isBn = langProvider.isBangla;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Top Actions: Globe (Lang) & Moon/Sun (Theme) Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.language_rounded,
                      color: isDark ? Colors.white70 : AppColors.primary,
                    ),
                    onPressed: () => langProvider.toggleLanguage(),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: isDark ? Colors.amber : AppColors.primary,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Brand Icon Logo Image
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Header Titles
              Text(
                isBn ? 'স্বাগতম' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isBn ? 'মানসিক স্বাস্থ্যের জন্য আপনার নিরাপদ ঠিকানা' : 'Your Safe Space for Mental Wellness',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 36),

              // Form Credentials
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'ইউজারনেম অথবা ইমেইল' : 'Username or Email',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.emergency, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      isBn ? 'পাসওয়ার্ড' : 'Password',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (val) {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        errorText: _passwordError,
                        errorStyle: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.emergency, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Login Button
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isBn ? 'লগইন' : 'Login',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),

              // Social Auth Section ("Or continue with Google")
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      isBn ? 'অথবা চালিয়ে যান' : 'Or continue with',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // Google Button Only (Facebook Removed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authProvider.isLoading ? null : _handleGoogleLogin,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (ctx, err, stack) => const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                  ),
                  label: Text(
                    isBn ? 'Google অ্যাকাউন্ট দিয়ে চালিয়ে যান' : 'Continue with Google',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Footer Link ("Don't have an account? Sign Up")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isBn ? 'একাউন্ট নেই? ' : "Don't have an account? ",
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      isBn ? 'সাইন আপ' : 'Sign Up',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
