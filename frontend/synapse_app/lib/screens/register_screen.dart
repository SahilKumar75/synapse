// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _sliderItems = [
    {
      'title': 'Welcome to Synapse!',
      'subtitle': 'Connect, collaborate, and grow your business.'
    },
    {
      'title': 'Smart Matching',
      'subtitle': 'Find the best opportunities tailored for you.'
    },
    {
      'title': 'Secure & Fast',
      'subtitle': 'Your data is protected and always accessible.'
    },
  ];

  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() { _isLoading = true; });

    final errorMessage = await _authService.register(
      name: _nameController.text,
      company: _companyController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful! Please log in.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back to the login screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7F6),
      body: Row(
        children: [
          // Left Panel: Register Form & Branding
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 22,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/logo.svg',
                        height: 32,
                        width: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SYNAPSE',
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 1.2,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create your account',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign up to get started with Synapse.',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              hintText: 'Enter your full name',
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company Name',
                              border: OutlineInputBorder(),
                              hintText: 'Enter your company name',
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              hintText: 'Enter your email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              hintText: 'Enter your password',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Color(0xFF007AFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('© SYNAPSE', style: TextStyle(fontSize: 12, color: Colors.black38)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Panel: Slider Info
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFF6F7FB),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _sliderItems.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final item = _sliderItems[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['subtitle']!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_sliderItems.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == index ? 16 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index ? const Color(0xFF007AFF) : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
