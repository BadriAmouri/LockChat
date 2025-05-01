// views/screens/incoming_requests.dart
import 'package:flutter/material.dart';
import 'package:lockchat/services/chat_service.dart';
import '../theme/colors.dart';
import '../widgets/request_item.dart';
import '../widgets/header_backButton.dart';
import 'send_request_screen.dart';
import '../../services/invitation_service.dart';
import '../../models/invitation.dart';

class ChatRequestListScreen extends StatefulWidget {
  const ChatRequestListScreen({super.key});

  @override
  State<ChatRequestListScreen> createState() => _ChatRequestListScreenState();
}

class _ChatRequestListScreenState extends State<ChatRequestListScreen> {
  List<Invitation> _requests = [];
  bool _isLoading = true;
  final InvitationService _invitationService = InvitationService();

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invitations = await _invitationService.getPendingInvitations();
      
      setState(() {
        _requests = invitations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading invitations: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load pending requests'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleConfirm(int invitationId, String username) async {
    try {
      final result = await _invitationService.respondToInvitation(invitationId, 'accept');
      if (result != null) {
        setState(() {
          _requests.removeWhere((request) => request.invitationId == invitationId);
        });

        await ChatService.createChatroom('private_chatroom',result['inviter_id'],true);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request from $username accepted!'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error accepting invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDecline(int invitationId, String username) async {
    try {
      final result = await _invitationService.respondToInvitation(invitationId, 'decline');
      
      if (result != null) {
        setState(() {
          _requests.removeWhere((request) => request.invitationId == invitationId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request from $username declined'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error declining invitation: $e');
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SendRequestScreen()),
          ).then((_) => _loadInvitations()); // Refresh when returning from send request screen
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Purple wave top decoration
          HeaderWaveWidget(title: 'PWA', subtitle: 'Chat requests'),

          // Request count and refresh button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Requests (${_requests.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Row with refresh and send request buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadInvitations,
                      icon: const Icon(Icons.refresh, color: AppColors.darkpurple),
                      tooltip: 'Refresh',
                    ),
                    
                  ],
                ),
              ],
            ),
          ),

          // Request list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: AppColors.subtitle,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No pending requests',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.subtitle,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final formattedDate = '${request.createdAt.year}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.day.toString().padLeft(2, '0')}';
                          return RequestItem(
                            username: request.inviterName,
                            date: formattedDate,
                            onConfirm: () => _handleConfirm(request.invitationId, request.inviterName),
                            onDecline: () => _handleDecline(request.invitationId, request.inviterName),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}