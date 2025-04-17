import 'package:flutter/material.dart';
import 'package:lockchat/views/screens/chat_list_screen.dart';
import '../../services/authService.dart';
import '../../services/tokenStorage.dart';
import '../theme/colors.dart';
import '../widgets/header.dart';
import 'signup.dart';
import 'two_factor_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _usernameError;
  String? _passwordError;
  bool _loading = false;
  String? _loginError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _usernameError = null;
      _passwordError = null;
      _loginError = null;
    });

    if (_usernameController.text.isEmpty) {
      _usernameError = 'Username is required';
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validateInputs()) return;

    setState(() {
      _loading = true;
      _loginError = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final result = await _authService.login(username, password);

    if (result['success']) {
      await _tokenStorage.saveTokens(
        result['accessToken'],
        result['refreshToken'],
      );

      await _tokenStorage.saveTokens(
        result['accessToken'],
        result['refreshToken'],
      );
      await _tokenStorage.saveUserId(result['user_id'].toString());



      
      final storedAccessToken = await _tokenStorage.getAccessToken();
      print(
        "🟢 [DEBUG] Access Token Stored Securely: 🔐\n$storedAccessToken\n",
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.buttonColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatListScreen(),
          ),
        );
      }
    } else {
      setState(() {
        _loginError = result['error'] ?? 'Login failed';
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeaderWidget(text: "PWA"),
            const SizedBox(height: 20),
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
                  Row(
                    children: [
                      Icon(Icons.login_rounded, color: AppColors.darkpurple),
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
                        if (_loginError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _loginError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
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
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Row(
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
