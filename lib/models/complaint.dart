class ComplaintReply {
  final String message;
  final bool isFromTailor;
  final DateTime timestamp;
  final String senderName;

  ComplaintReply({
    required this.message,
    required this.isFromTailor,
    required this.senderName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'isFromTailor': isFromTailor,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
    };
  }

  factory ComplaintReply.fromMap(Map<String, dynamic> map) {
    DateTime _toDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return ComplaintReply(
      message: map['message'] as String? ?? '',
      isFromTailor: map['isFromTailor'] == true || map['isFromTailor'] == 1,
      timestamp: _toDate(map['timestamp']),
      senderName: map['senderName'] as String? ?? '',
    );
  }
}

class Complaint {
  final int? id; // legacy local id
  final String? docId; // Firestore document id
  final String customerName;
  final String customerEmail; // New field
  final String category; // New field: 'delay', 'quality', 'pickup', 'other'
  final String subject; // New field: complaint title
  final String message;
  final String? attachmentUrl; // New field: optional image attachment
  final String? reply; // Kept for backward compatibility
  final DateTime createdAt;
  final bool isResolved; // Kept for backward compatibility
  final String status; // New field: 'open', 'in_progress', 'resolved'
  final List<ComplaintReply> replies; // New field: conversation thread

  final String customerId; // New field for direct querying
  final String? tailorId; // Optional link to specific tailor

  Complaint({
    this.id,
    this.docId,
    required this.customerId,
    this.tailorId,
    required this.customerName,
    required this.customerEmail,
    this.category = 'other',
    this.subject = '',
    required this.message,
    this.attachmentUrl,
    this.reply,
    DateTime? createdAt,
    this.isResolved = false,
    String? status,
    List<ComplaintReply>? replies,
  })  : createdAt = createdAt ?? DateTime.now(),
        status = status ?? (isResolved ? 'resolved' : 'open'),
        replies = replies ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'docId': docId,
      'customerId': customerId,
      'tailorId': tailorId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'category': category,
      'subject': subject,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'reply': reply,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved ? 1 : 0,
      'status': status,
      'replies': replies.map((r) => r.toMap()).toList(),
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    DateTime _toDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    List<ComplaintReply> _parseReplies(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value
            .map((item) => ComplaintReply.fromMap(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    final isResolved = map['isResolved'] is bool
        ? map['isResolved'] as bool
        : (map['isResolved'] as int?) == 1;

    return Complaint(
      id: map['id'] as int?,
      docId: map['docId'] as String?,
      customerId: map['customerId'] as String? ?? '',
      tailorId: map['tailorId'] as String?,
      customerName: map['customerName'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      attachmentUrl: map['attachmentUrl'] as String?,
      reply: map['reply'] as String?,
      createdAt: _toDate(map['createdAt']),
      isResolved: isResolved,
      status: map['status'] as String? ?? (isResolved ? 'resolved' : 'open'),
      replies: _parseReplies(map['replies']),
    );
  }

  Complaint copyWith({
    int? id,
    String? docId,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? category,
    String? subject,
    String? message,
    String? attachmentUrl,
    String? reply,
    DateTime? createdAt,
    bool? isResolved,
    String? status,
    List<ComplaintReply>? replies,
  }) {
    return Complaint(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      reply: reply ?? this.reply,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      status: status ?? this.status,
      replies: replies ?? this.replies,
    );
  }
}
