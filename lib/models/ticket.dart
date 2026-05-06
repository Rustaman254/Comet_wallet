import 'dart:convert';

class Ticket {
  final String ticketId;
  final int? userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String issueCategory;
  final String issueDescription;
  final String currentStatus;
  final String assignedTo;
  final String adminComments;
  final DateTime ticketCreatedOn;

  Ticket({
    required this.ticketId,
    this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.issueCategory,
    required this.issueDescription,
    required this.currentStatus,
    required this.assignedTo,
    required this.adminComments,
    required this.ticketCreatedOn,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'] ?? '',
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      issueCategory: json['issue_category'] ?? '',
      issueDescription: json['issue_description'] ?? '',
      currentStatus: json['current_status'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      adminComments: json['admin_comments'] ?? '',
      ticketCreatedOn: json['ticket_created_on'] != null
          ? DateTime.parse(json['ticket_created_on'])
          : (json['CreatedAt'] != null 
              ? DateTime.parse(json['CreatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'issue_category': issueCategory,
      'issue_description': issueDescription,
      'current_status': currentStatus,
      'assigned_to': assignedTo,
      'admin_comments': adminComments,
      'ticket_created_on': ticketCreatedOn.toIso8601String(),
    };
  }
}
