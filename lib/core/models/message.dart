import 'package:cloud_firestore/cloud_firestore.dart';

enum MessagePriority { normal, urgent, critical }
enum MessageChannel  { allStaff, security, medical, management, guestAlert }

extension MessageChannelExt on MessageChannel {
  String get label {
    switch (this) {
      case MessageChannel.allStaff:    return 'All Staff';
      case MessageChannel.security:    return 'Security';
      case MessageChannel.medical:     return 'Medical';
      case MessageChannel.management:  return 'Management';
      case MessageChannel.guestAlert:  return 'Guest Alert';
    }
  }
  String get icon {
    switch (this) {
      case MessageChannel.allStaff:    return '📢';
      case MessageChannel.security:    return '🛡️';
      case MessageChannel.medical:     return '🩺';
      case MessageChannel.management:  return '👔';
      case MessageChannel.guestAlert:  return '🏨';
    }
  }
}

extension MessagePriorityExt on MessagePriority {
  String get label {
    switch (this) {
      case MessagePriority.normal:   return 'Normal';
      case MessagePriority.urgent:   return 'Urgent';
      case MessagePriority.critical: return 'Critical';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final MessageChannel channel;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final MessagePriority priority;
  final DateTime timestamp;
  final bool isSystemMessage;
  final String? relatedIncidentId;

  const ChatMessage({
    required this.id,
    required this.channel,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.priority,
    required this.timestamp,
    this.isSystemMessage = false,
    this.relatedIncidentId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id:                d.containsKey('id') ? d['id'] as String : doc.id,
      channel:           MessageChannel.values.byName(d['channel'] as String),
      senderId:          d['senderId'] as String,
      senderName:        d['senderName'] as String,
      senderRole:        d['senderRole'] as String,
      content:           d['content'] as String,
      priority:          MessagePriority.values.byName(d['priority'] as String),
      timestamp:         (d['timestamp'] as Timestamp).toDate(),
      isSystemMessage:   d['isSystemMessage'] as bool? ?? false,
      relatedIncidentId: d['relatedIncidentId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id':                id,
    'channel':           channel.name,
    'senderId':          senderId,
    'senderName':        senderName,
    'senderRole':        senderRole,
    'content':           content,
    'priority':          priority.name,
    'timestamp':         Timestamp.fromDate(timestamp),
    'isSystemMessage':   isSystemMessage,
    'relatedIncidentId': relatedIncidentId,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Chat message (Gemma 4)
// ─────────────────────────────────────────────────────────────────────────────
class AiMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const AiMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
