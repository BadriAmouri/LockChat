import 'package:flutter/material.dart';
import 'package:lockchat/views/widgets/header_backButton.dart';
import 'security_settings.dart';
import 'change_profile_picture_screen.dart';
import 'package:lockchat/services/tokenStorage.dart';
import 'package:lockchat/services/authService.dart';
import 'login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool _showUsernameField = false;
  bool _showEmailField = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username cannot be empty';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Methods to handle field submissions
  void _saveUsername() async {
    if (_formKey.currentState!.validate()) {
      final currentUsername = await TokenStorage().getUsername();
      final newUsername = _usernameController.text.trim();
      if (currentUsername == null || newUsername.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a new username.')),
        );
        return;
      }
      final result = await AuthService().updateUsername(currentUsername, newUsername);
      if (result['success']) {
        await TokenStorage().saveUsername(newUsername);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        setState(() {
          _showUsernameField = false;
          _usernameController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to update username')),
        );
      }
    }
  }

  void _saveEmail() async {
    if (_formKey.currentState!.validate()) {
      final username = await TokenStorage().getUsername();
      final newEmail = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (username == null || newEmail.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        return;
      }
      final result = await AuthService().updateEmail(username, newEmail, password);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        setState(() {
          _showEmailField = false;
          _emailController.clear();
          _passwordController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to update email')),
        );
      }
    }
  }

  void _logout() async {
    try {
      final tokenStorage = TokenStorage();
      final refreshToken = await tokenStorage.getRefreshToken();
      
      if (refreshToken == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active session found')),
          );
        }
        return;
      }

      final authService = AuthService();
      final result = await authService.logout(refreshToken);

      if (result['success']) {
        // Clear stored tokens
        await tokenStorage.clearTokens();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully')),
          );
          // Navigate to login page using MaterialPageRoute
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // This removes all previous routes
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Logout failed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  void _toggleUsernameField() {
    setState(() {
      _showUsernameField = !_showUsernameField;
      if (_showUsernameField) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _usernameController.clear();
      }
    });
  }

  void _toggleEmailField() {
    setState(() {
      _showEmailField = !_showEmailField;
      if (_showEmailField) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _emailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Purple wave with PWA header
              HeaderWaveWidget(title: 'PWA', subtitle: 'Settings'),

              // Main content - Settings items
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        // About PWA section
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to About page or show dialog
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: const Text(
                              'About PWA',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                        // Security Settings section
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to Security Settings page
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: GestureDetector(
                              child: const Text(
                                'Security Settings',
                                style: TextStyle(fontSize: 18),
                              ),
                              onTap: () {
                                // Navigate to security settings page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => SecuritySettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Change Username section
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _toggleUsernameField,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Change Username',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    AnimatedRotation(
                                      turns: _showUsernameField ? 0.25 : 0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child:
                                    _showUsernameField
                                        ? FadeTransition(
                                          opacity: _animation,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextFormField(
                                                  controller:
                                                      _usernameController,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            'Enter new username',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  validator: _validateUsername,
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton(
                                                  onPressed: _saveUsername,
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),

                        // Change Email section
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _toggleEmailField,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Change Email',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    AnimatedRotation(
                                      turns: _showEmailField ? 0.25 : 0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child:
                                    _showEmailField
                                        ? FadeTransition(
                                          opacity: _animation,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextFormField(
                                                  controller: _emailController,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            'Enter new email',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  validator: _validateEmail,
                                                  keyboardType:
                                                      TextInputType
                                                          .emailAddress,
                                                ),
                                                TextFormField(
                                                  controller: _passwordController,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter your password',
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  obscureText: true,
                                                  validator: (value) => value == null || value.isEmpty ? 'Password required' : null,
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton(
                                                  onPressed: _saveEmail,
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        
                        // Change Profile Picture section
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to Profile Picture Change Page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangeProfilePictureScreen(), // (to be created)
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'Change Profile Picture',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),

                      ],
                    ),
                  ),
                ),
              ),

              // Logout button at the bottom
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Log Out', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
