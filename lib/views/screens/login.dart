// views/screens/login_screen.dart
// views/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/wave_clipper.dart';
import 'signup.dart';
import 'chat_screen_test.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  // Error messages
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Validation methods
  bool _validateInputs() {
    bool isValid = true;
    
    // Reset errors
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });
    
    // Username validation
    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = 'Username is required';
      });
      isValid = false;
      
    }
    
    // Email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      isValid = false;
    } else if (!emailRegExp.hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      isValid = false;
    }
    
    // Password validation
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters';
      });
      isValid = false;
    }
    
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Purple wave with PWA text
            Stack(
              children: [
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    height: 300,
                    color: AppColors.darkpurple.withOpacity(0.8),
                  ),
                ),
                const Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'PWA',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 3,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Login On Your Account
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login On Your Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Login tab indicator
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        color: AppColors.darkpurple,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Purple line
                  Container(
                    height: 3,
                    color: AppColors.darkpurple,
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                  ),
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username field
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Unique Username',
                            hintText: 'username123',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            errorText: _usernameError,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'example@email.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            errorText: _emailError,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                  
                  // Next Step button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_validateInputs()) {
                          // Login successful, navigate to next screen
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login successful!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(),
                              ),
                            );
                          
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Next Step'),
                          SizedBox(width: 8),
                          Icon(Icons.fast_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Don't have account? Sign Up
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have account? ",
                          style: TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: AppColors.darkpurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}