// views/screens/send_request_screen.dart
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

  // Sample user data for local testing - in a real app, this would come from API
  final List<Map<String, dynamic>> _allUsers = [
    {'id': 10, 'username': 'alex_tech'},
    {'id': 'user2', 'username': 'maria_design'},
    {'id': 'user3', 'username': 'dev_master'},
    {'id': 'user4', 'username': 'jay_smith'},
    {'id': 'user5', 'username': 'app_lover'},
    {'id': 'user6', 'username': 'flutter_fan'},
    {'id': 'user7', 'username': 'code_ninja'},
    {'id': 'user8', 'username': 'dart_expert'},
    {'id': 'user9', 'username': 'moussa'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Debounce search to avoid too many API calls
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

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

    // Using local search until API endpoint is available
    // Note: In production, switch to API call
    try {
      final results = _allUsers
          .where((user) => user['username'].toLowerCase().contains(query))
          .toList();
      
      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isLoading = false;
      });
    }

    // Uncomment this section when API is ready
    /*
    _invitationService.searchUsers(query).then((results) {
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    }).catchError((e) {
      print('Error searching users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    */
  }

  Future<void> _sendRequest(int userId, String username) async {
    try {
      final result = await _invitationService.sendInvitation(userId);
      print(result);
      if (result) {
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
          // Purple wave with PWA header
          HeaderWaveWidget(title: 'PWA', subtitle: 'Find Friends'),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for username',
                prefixIcon: Icon(Icons.search, color: AppColors.darkpurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Search instructions or results
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
                                username: user['username'],
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
                              'Start typing to see results',
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