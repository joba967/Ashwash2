import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
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
  String _selectedRole = 'PATIENT';

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
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

    final selectedAccount = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _GoogleAccountPickerSheet(isBn: isBn),
    );

    if (selectedAccount == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle(
      email: selectedAccount['email']!,
      name: selectedAccount['name']!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'গুগল অ্যাকাউন্ট দিয়ে সফলভাবে লগইন হয়েছে!' : 'Logged in with Google successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google login failed.'),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  Future<void> _handleFacebookLogin() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    final selectedAccount = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FacebookAccountPickerSheet(isBn: isBn),
    );

    if (selectedAccount == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithFacebook(
      email: selectedAccount['email']!,
      name: selectedAccount['name']!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'ফেসবুক অ্যাকাউন্ট দিয়ে সফলভাবে লগইন হয়েছে!' : 'Logged in with Facebook successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Facebook login failed.'),
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

              // Top Actions: Globe (Lang) & Moon (Theme) Icons (Matching Figma)
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

              // Brand Icon Logo Image (Official Ashwash Logo)
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
                    // Form Inputs

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

              // Login Button (Pill shaped, vibrant purple matching Figma Screen 4)
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

              // Social Auth Section ("Or continue with")
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

              // Social Google and Facebook Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : _handleGoogleLogin,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (ctx, err, stack) => const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                      ),
                      label: const Text('Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : _handleFacebookLogin,
                      icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                      label: const Text('Facebook', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
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

class _GoogleAccountPickerSheet extends StatefulWidget {
  final bool isBn;
  const _GoogleAccountPickerSheet({required this.isBn});

  @override
  State<_GoogleAccountPickerSheet> createState() => _GoogleAccountPickerSheetState();
}

class _GoogleAccountPickerSheetState extends State<_GoogleAccountPickerSheet> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isCustom = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBn;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                width: 24,
                height: 24,
                errorBuilder: (ctx, err, stack) => const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.red)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBn ? 'আশ্বাসে চালিয়ে যেতে একটি গুগল অ্যাকাউন্ট বেছে নিন' : 'Choose an account to continue to Ashwash',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: const Text('Google User', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('google.user@gmail.com'),
            onTap: () => Navigator.pop(context, {'email': 'google.user@gmail.com', 'name': 'Google User'}),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: const Text('Ashwash Patient', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('ashwash.patient@gmail.com'),
            onTap: () => Navigator.pop(context, {'email': 'ashwash.patient@gmail.com', 'name': 'Ashwash Patient'}),
          ),
          const Divider(),
          if (!_isCustom)
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(isBn ? 'অন্য গুগল অ্যাকাউন্ট যোগ বা ব্যবহার করুন' : 'Use another account'),
              onTap: () => setState(() => _isCustom = true),
            )
          else ...[
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isBn ? 'আপনার নাম' : 'Your Name',
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isBn ? 'গুগল ইমেইল (e.g. user@gmail.com)' : 'Google Email (e.g. user@gmail.com)',
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final email = _emailCtrl.text.trim();
                final name = _nameCtrl.text.trim();
                if (email.isNotEmpty && email.contains('@')) {
                  Navigator.pop(context, {'email': email, 'name': name.isEmpty ? 'Google User' : name});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isBn ? 'চালিয়ে যান' : 'Continue', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FacebookAccountPickerSheet extends StatefulWidget {
  final bool isBn;
  const _FacebookAccountPickerSheet({required this.isBn});

  @override
  State<_FacebookAccountPickerSheet> createState() => _FacebookAccountPickerSheetState();
}

class _FacebookAccountPickerSheetState extends State<_FacebookAccountPickerSheet> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isCustom = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBn;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBn ? 'ফেসবুক অ্যাকাউন্ট বেছে নিয়ে আশ্বাসে প্রবেশ করুন' : 'Log in with Facebook to continue to Ashwash',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1877F2),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text('Facebook User', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('facebook.user@ashwash.com'),
            onTap: () => Navigator.pop(context, {'email': 'facebook.user@ashwash.com', 'name': 'Facebook User'}),
          ),
          const Divider(),
          if (!_isCustom)
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(isBn ? 'অন্য ফেসবুক অ্যাকাউন্টে লগইন করুন' : 'Log in to another account'),
              onTap: () => setState(() => _isCustom = true),
            )
          else ...[
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isBn ? 'আপনার নাম' : 'Your Name',
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isBn ? 'ফেসবুক ইমেইল বা ফোন নম্বর' : 'Facebook Email or Phone Number',
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final email = _emailCtrl.text.trim();
                final name = _nameCtrl.text.trim();
                if (email.isNotEmpty) {
                  final validEmail = email.contains('@') ? email : '$email@facebook.com';
                  Navigator.pop(context, {'email': validEmail, 'name': name.isEmpty ? 'Facebook User' : name});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isBn ? 'লগইন করুন' : 'Log In', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
