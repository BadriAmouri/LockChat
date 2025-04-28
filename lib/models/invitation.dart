class Invitation {
  final int invitationId;
  final int inviterId;
  final String inviterName;
  final int invitedUserId;
  final String status;
  final DateTime createdAt;
  
  Invitation({
    required this.invitationId,
    required this.inviterId,
    required this.inviterName,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
  });
  
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      invitationId: json['invitation_id'],
      inviterId: json['inviter_id'],
      inviterName: json['users']?['full_name'] ?? 'Unknown User',
      invitedUserId: json['invited_user_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'invitation_id': invitationId,
      'inviter_id': inviterId,
      'invited_user_id': invitedUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}