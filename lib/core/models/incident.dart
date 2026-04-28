import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentSeverity { critical, high, medium, low }
enum IncidentStatus  { reported, active, inProgress, resolved }
enum IncidentType {
  fire, medical, security, naturalDisaster,
  utilityFailure, evacuation, hazmat, other
}

extension IncidentSeverityExt on IncidentSeverity {
  String get label => name[0].toUpperCase() + name.substring(1);
  String get emoji {
    switch (this) {
      case IncidentSeverity.critical: return '🔴';
      case IncidentSeverity.high:     return '🟠';
      case IncidentSeverity.medium:   return '🟡';
      case IncidentSeverity.low:      return '🟢';
    }
  }
}

extension IncidentStatusExt on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.reported:   return 'Reported';
      case IncidentStatus.active:     return 'Active';
      case IncidentStatus.inProgress: return 'In Progress';
      case IncidentStatus.resolved:   return 'Resolved';
    }
  }
}

extension IncidentTypeExt on IncidentType {
  String get label {
    switch (this) {
      case IncidentType.fire:            return 'Fire';
      case IncidentType.medical:         return 'Medical';
      case IncidentType.security:        return 'Security Breach';
      case IncidentType.naturalDisaster: return 'Natural Disaster';
      case IncidentType.utilityFailure:  return 'Utility Failure';
      case IncidentType.evacuation:      return 'Evacuation';
      case IncidentType.hazmat:          return 'HazMat';
      case IncidentType.other:           return 'Other';
    }
  }
  String get icon {
    switch (this) {
      case IncidentType.fire:            return '🔥';
      case IncidentType.medical:         return '🏥';
      case IncidentType.security:        return '🔒';
      case IncidentType.naturalDisaster: return '🌪️';
      case IncidentType.utilityFailure:  return '⚡';
      case IncidentType.evacuation:      return '🚪';
      case IncidentType.hazmat:          return '☣️';
      case IncidentType.other:           return '⚠️';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class IncidentUpdate {
  final String id;
  final String message;
  final String authorName;
  final String authorRole;
  final DateTime timestamp;

  const IncidentUpdate({
    required this.id,
    required this.message,
    required this.authorName,
    required this.authorRole,
    required this.timestamp,
  });

  factory IncidentUpdate.fromMap(Map<String, dynamic> map) => IncidentUpdate(
    id:         map['id'] as String,
    message:    map['message'] as String,
    authorName: map['authorName'] as String,
    authorRole: map['authorRole'] as String,
    timestamp:  (map['timestamp'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'id':         id,
    'message':    message,
    'authorName': authorName,
    'authorRole': authorRole,
    'timestamp':  Timestamp.fromDate(timestamp),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
class Incident {
  final String id;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String title;
  final String description;
  final String location;
  final int floor;
  final String? roomNumber;
  final String reportedBy;
  final String reporterRole;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final List<String> assignedPersonnelIds;
  final List<IncidentUpdate> updates;
  final int guestsAffected;

  const Incident({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    required this.location,
    required this.floor,
    this.roomNumber,
    required this.reportedBy,
    required this.reporterRole,
    required this.reportedAt,
    this.resolvedAt,
    this.assignedPersonnelIds = const [],
    this.updates = const [],
    this.guestsAffected = 0,
  });

  Incident copyWith({
    IncidentStatus? status,
    List<String>? assignedPersonnelIds,
    List<IncidentUpdate>? updates,
    DateTime? resolvedAt,
  }) => Incident(
    id:                   id,
    type:                 type,
    severity:             severity,
    status:               status ?? this.status,
    title:                title,
    description:          description,
    location:             location,
    floor:                floor,
    roomNumber:           roomNumber,
    reportedBy:           reportedBy,
    reporterRole:         reporterRole,
    reportedAt:           reportedAt,
    resolvedAt:           resolvedAt ?? this.resolvedAt,
    assignedPersonnelIds: assignedPersonnelIds ?? this.assignedPersonnelIds,
    updates:              updates ?? this.updates,
    guestsAffected:       guestsAffected,
  );

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Incident(
      id:          doc.id,
      type:        IncidentType.values.byName(d['type'] as String),
      severity:    IncidentSeverity.values.byName(d['severity'] as String),
      status:      IncidentStatus.values.byName(d['status'] as String),
      title:       d['title'] as String,
      description: d['description'] as String,
      location:    d['location'] as String,
      floor:       d['floor'] as int,
      roomNumber:  d['roomNumber'] as String?,
      reportedBy:  d['reportedBy'] as String,
      reporterRole: d['reporterRole'] as String,
      reportedAt:  (d['reportedAt'] as Timestamp).toDate(),
      resolvedAt:  d['resolvedAt'] != null ? (d['resolvedAt'] as Timestamp).toDate() : null,
      assignedPersonnelIds: List<String>.from(d['assignedPersonnelIds'] ?? []),
      updates: (d['updates'] as List<dynamic>? ?? [])
          .map((u) => IncidentUpdate.fromMap(u as Map<String, dynamic>))
          .toList(),
      guestsAffected: d['guestsAffected'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type':                 type.name,
    'severity':             severity.name,
    'status':               status.name,
    'title':                title,
    'description':          description,
    'location':             location,
    'floor':                floor,
    'roomNumber':           roomNumber,
    'reportedBy':           reportedBy,
    'reporterRole':         reporterRole,
    'reportedAt':           Timestamp.fromDate(reportedAt),
    'resolvedAt':           resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'assignedPersonnelIds': assignedPersonnelIds,
    'updates':              updates.map((u) => u.toMap()).toList(),
    'guestsAffected':       guestsAffected,
  };
}
