import 'package:cloud_firestore/cloud_firestore.dart';

enum PersonnelStatus { available, deployed, offDuty, emergency }
enum PersonnelRole   { security, medical, management, housekeeping, frontDesk, maintenance }

extension PersonnelStatusExt on PersonnelStatus {
  String get label {
    switch (this) {
      case PersonnelStatus.available:  return 'Available';
      case PersonnelStatus.deployed:   return 'Deployed';
      case PersonnelStatus.offDuty:    return 'Off Duty';
      case PersonnelStatus.emergency:  return 'Emergency';
    }
  }
}

extension PersonnelRoleExt on PersonnelRole {
  String get label {
    switch (this) {
      case PersonnelRole.security:     return 'Security';
      case PersonnelRole.medical:      return 'Medical';
      case PersonnelRole.management:   return 'Management';
      case PersonnelRole.housekeeping: return 'Housekeeping';
      case PersonnelRole.frontDesk:    return 'Front Desk';
      case PersonnelRole.maintenance:  return 'Maintenance';
    }
  }
  String get icon {
    switch (this) {
      case PersonnelRole.security:     return '🛡️';
      case PersonnelRole.medical:      return '🩺';
      case PersonnelRole.management:   return '👔';
      case PersonnelRole.housekeeping: return '🧹';
      case PersonnelRole.frontDesk:    return '🏨';
      case PersonnelRole.maintenance:  return '🔧';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class Personnel {
  final String id;
  final String name;
  final PersonnelRole role;
  final PersonnelStatus status;
  final String phone;
  final String? currentLocation;
  final String? assignedIncidentId;
  final double avgResponseMinutes;
  final String avatarInitials;

  const Personnel({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.phone,
    this.currentLocation,
    this.assignedIncidentId,
    this.avgResponseMinutes = 3.5,
    required this.avatarInitials,
  });

  Personnel copyWith({
    PersonnelStatus? status,
    String? currentLocation,
    String? assignedIncidentId,
  }) => Personnel(
    id:                   id,
    name:                 name,
    role:                 role,
    status:               status ?? this.status,
    phone:                phone,
    currentLocation:      currentLocation ?? this.currentLocation,
    assignedIncidentId:   assignedIncidentId,
    avgResponseMinutes:   avgResponseMinutes,
    avatarInitials:       avatarInitials,
  );

  factory Personnel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Personnel(
      id:                 doc.id,
      name:               d['name'] as String,
      role:               PersonnelRole.values.byName(d['role'] as String),
      status:             PersonnelStatus.values.byName(d['status'] as String),
      phone:              d['phone'] as String,
      currentLocation:    d['currentLocation'] as String?,
      assignedIncidentId: d['assignedIncidentId'] as String?,
      avgResponseMinutes: (d['avgResponseMinutes'] as num?)?.toDouble() ?? 3.5,
      avatarInitials:     d['avatarInitials'] as String? ?? '??',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':               name,
    'role':               role.name,
    'status':             status.name,
    'phone':              phone,
    'currentLocation':    currentLocation,
    'assignedIncidentId': assignedIncidentId,
    'avgResponseMinutes': avgResponseMinutes,
    'avatarInitials':     avatarInitials,
  };
}
