import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../widgets/header.dart';
import 'login.dart';
import '../../services/keyGeneration.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Error messages
  String? _fullNameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;

    try {
      final supabase = Supabase.instance.client;
      final fileBytes = await _profileImage!.readAsBytes();
      final fileExt = _profileImage!.path.split('.').last;
      final fileName = 'user_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload file
      await supabase.storage.from('profilepictures').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
          contentType: 'image/$fileExt',
        ),
      );

      // Get public URL
      final publicUrl = supabase.storage.from('profilepictures').getPublicUrl(fileName);

      if (publicUrl.isEmpty) {
        throw Exception('Failed to get public URL');
      }

      return publicUrl;
    } catch (e) {
      print('❌ Error in _uploadProfileImage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload profile image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    // Reset errors
    setState(() {
      _fullNameError = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });

    // Full name validation
    if (_fullNameController.text.isEmpty) {
      setState(() {
        _fullNameError = 'Full name is required';
      });
      isValid = false;
    }

    // Username validation
    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = 'Username is required';
      });
      isValid = false;
    } else if (_usernameController.text.trim() == 'moussa') {
      setState(() {
        _usernameError = 'Username is already taken';
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
            HeaderWidget(text: "PWA"),

            const SizedBox(height: 20),

            // Sign Up for Account
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign Up for Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign Up tab indicator
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: AppColors.darkpurple,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign Up',
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

                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.darkpurple.withOpacity(0.1),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.darkpurple,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkpurple,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full name field
                        TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            errorText: _fullNameError,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Username field
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Unique Username',
                            hintText: 'Enter a username',
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
                            hintText: 'Enter your email',
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
                            hintText: 'Create a password',
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
                                    ? Icons.lock_outline
                                    : Icons.lock_open_outlined,
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

                  // Create Account button
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_validateInputs()) {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // Upload profile image if exists
                            final imageUrl = await _uploadProfileImage();
                            print('🖼️ Image URL before registration: $imageUrl'); // Debug print

                            if (_profileImage != null && imageUrl == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to upload profile image. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() {
                                _isLoading = false;
                              });
                              return;
                            }

                            final result = await KeyGenerationService.generateAndStoreKeyPair(
                              _usernameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text,
                              fullName: _fullNameController.text.trim(),
                              profileImageUrl: imageUrl,
                            );

                            print('📝 Registration result: $result'); // Debug print

                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Signup failed: ${result['error']}"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            print('❌ Error during registration: $e'); // Debug print
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Unexpected error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Already have account? LogIn
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "You have account? ",
                          style: TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "LogIn",
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
