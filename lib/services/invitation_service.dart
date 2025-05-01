// services/invitation_service.dart
import 'dart:convert';
import 'dart:ffi';
import '../models/invitation.dart';
import 'jwt_handler.dart';

class InvitationService {
  static const String baseUrl = 'https://lock-chat-backend.vercel.app';
  static const String sendInvitationEndpoint = 'api/Invitations/sendInvitation';
  static const String getPendingInvitationsEndpoint = 'api/Invitations/getPendingInvitations';
  static const String respondToInvitationBaseEndpoint = 'api/Invitations';

  final JwtHandler _jwtHandler = JwtHandler();

  // Send invitation to a user
  Future<bool> sendInvitation(int invitedUserId) async {
    try {
      final response = await _jwtHandler.authenticatedPost(
        sendInvitationEndpoint, 
        {'invitedUserId': invitedUserId}
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to send invitation: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending invitation: $e');
      return false;
    }
  }

  // Get pending invitations for the current user
  Future<List<Invitation>> getPendingInvitations() async {
    try {
      final response = await _jwtHandler.authenticatedGet(getPendingInvitationsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Invitation.fromJson(json)).toList();
      } else {
        print('Failed to fetch invitations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching invitations: $e');
      return [];
    }
  }

  // Accept or decline an invitation
  Future<Map<String, dynamic>?> respondToInvitation(int invitationId, String action) async {
  try {
    final String endpoint = '$respondToInvitationBaseEndpoint/$invitationId/respond';
    final response = await _jwtHandler.authenticatedPost(
      endpoint,
      {'action': action}, // action should be 'accept' or 'decline'
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['invitation'] != null) {
        return responseData['invitation']; // return updated invitation
      } else {
        print('No updated invitation data found in response.');
        return null;
      }
    } else {
      print('Failed to respond to invitation: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error responding to invitation: $e');
    return null;
  }
}


  // Search for users to invite
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  try {
    if (query.trim().isEmpty) {
      print('Search query is empty');
      return [];
    }

    final String encodedQuery = Uri.encodeQueryComponent(query);
    final String searchEndpoint = 'api/users/searchUsers?query=$encodedQuery';

    final response = await _jwtHandler.authenticatedGet(searchEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Unexpected data format in response');
        return [];
      }
    } else {
      print('Failed to search users: ${response.statusCode} - ${response.body}');
      return [];
    }
  } catch (e, stackTrace) {
    print('Error searching users: $e');
    print(stackTrace);
    return [];
  }
}

}