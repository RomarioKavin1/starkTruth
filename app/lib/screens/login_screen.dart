import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/brutalist_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _walletController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  final _supabaseService = SupabaseService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final walletAddress = _walletController.text.trim();
      final username = _usernameController.text.trim();
      final bio = _bioController.text.trim();
      final profile = await _supabaseService.getUserProfile(walletAddress);

      if (profile == null) {
        await _supabaseService.createUserProfile(walletAddress, username, bio);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_address', walletAddress);
      await prefs.setString('username', username);
      await prefs.setString('bio', bio);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to login. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _walletController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Stark',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        'Truth',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Color(0xFF004AAD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Wallet Address
                  BrutalistContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BrutalistTextField(
                          controller: _walletController,
                          hintText: 'Enter your wallet address',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your wallet address';
                            }
                            if (!value.startsWith('0x') || value.length < 42) {
                              return 'Please enter a valid wallet address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Username
                  BrutalistContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BrutalistTextField(
                          controller: _usernameController,
                          hintText: 'Enter your username',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bio
                  BrutalistContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BrutalistTextField(
                          controller: _bioController,
                          hintText: 'Enter your bio',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a bio';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 24),
                    BrutalistContainer(
                      backgroundColor: Colors.red.shade50,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: BrutalistButton(
                      onPressed: _isLoading ? null : _login,
                      backgroundColor: const Color(0xFF004AAD),
                      child: Container(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
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
