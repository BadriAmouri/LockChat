import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/user_result_item.dart';
import '../widgets/header_backButton.dart';
import '../../services/invitation_service.dart';

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  final InvitationService _invitationService = InvitationService();

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await _invitationService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendRequest(int userId, String username) async {
    try {
      final result = await _invitationService.sendInvitation(userId);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat request sent to $username'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sending request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HeaderWaveWidget(title: 'PWA', subtitle: 'Find Friends'),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for username',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.person, color: AppColors.darkpurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.darkpurple,
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearching
                    ? _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.subtitle,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return UserResultItem(
                                username: user['full_name'],
                                onSendRequest: () => _sendRequest(
                                  user['id'],
                                  user['username'],
                                ),
                              );
                            },
                          )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: AppColors.subtitle,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Search for users by username',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.subtitle,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enter a username and press search',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
