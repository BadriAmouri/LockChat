import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/header_backButton.dart';
import '../../services/tokenStorage.dart';

class ChangeProfilePictureScreen extends StatefulWidget {
  const ChangeProfilePictureScreen({Key? key}) : super(key: key);

  @override
  State<ChangeProfilePictureScreen> createState() => _ChangeProfilePictureScreenState();
}

class _ChangeProfilePictureScreenState extends State<ChangeProfilePictureScreen> {
  final TokenStorage _tokenStorage = TokenStorage();
  final supabase = Supabase.instance.client;

  File? _selectedImage;
  String? _profilePicUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (userId == null) {
      return;
    }

    try {
      final response = await supabase
          .from('users')
          .select('profile_pic')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['profile_pic'] != null) {
        setState(() {
          _profilePicUrl = response['profile_pic'] as String;
        });
      }
    } catch (error) {
      print('Failed to load profile picture: $error');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      final fileBytes = await _selectedImage!.readAsBytes();
      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

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

      // Update profile_pic field in users table
      final updateResponse = await supabase
          .from('users')
          .update({'profile_pic': publicUrl})
          .eq('user_id', userId)
          .select()
          .maybeSingle();

      if (updateResponse == null) {
        throw Exception('Failed to update profile picture in database');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );

      setState(() {
        _selectedImage = null;
        _profilePicUrl = publicUrl; // Update the displayed profile pic
      });
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: $error')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const HeaderWaveWidget(title: 'PWA', subtitle: ''),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: AppColors.darkpurple.withOpacity(0.2),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_profilePicUrl != null
                                    ? NetworkImage(_profilePicUrl!)
                                    : const NetworkImage('https://via.placeholder.com/150')) as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.darkpurple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    _isUploading
                        ? const CircularProgressIndicator()
                        : CustomButton(
                            text: 'Save Changes',
                            onPressed: _uploadProfilePicture,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
