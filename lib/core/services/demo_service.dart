import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/incident.dart';
import '../models/personnel.dart';
import '../models/message.dart';

/// Generates realistic hospitality crisis demo data.
/// Used when Firebase is unavailable / during standalone preview.
class DemoService {
  final _uuid = const Uuid();
  final _rng  = Random();

  // ── Seed incidents ─────────────────────────────────────────────────────────
  List<Incident> seedIncidents() => [
    Incident(
      id: _uuid.v4(),
      type: IncidentType.fire,
      severity: IncidentSeverity.critical,
      status: IncidentStatus.active,
      title: 'Kitchen Fire – Restaurant',
      description: 'Smoke detected in the main kitchen. Fire suppression system activated. Staff evacuating.',
      location: 'Ground Floor – Main Kitchen',
      floor: 0,
      reportedBy: 'Chef Marco Rossi',
      reporterRole: 'Kitchen Manager',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      assignedPersonnelIds: ['p1', 'p2'],
      guestsAffected: 47,
      updates: [
        IncidentUpdate(
          id: _uuid.v4(),
          message: 'Fire suppression triggered. Evacuating restaurant area.',
          authorName: 'Security Team',
          authorRole: 'Security',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      ],
    ),
    Incident(
      id: _uuid.v4(),
      type: IncidentType.medical,
      severity: IncidentSeverity.high,
      status: IncidentStatus.inProgress,
      title: 'Guest Cardiac Episode – Room 412',
      description: 'Guest unresponsive. AED deployed. Paramedics en route.',
      location: 'Floor 4 – Room 412',
      floor: 4,
      roomNumber: '412',
      reportedBy: 'Housekeeping Staff',
      reporterRole: 'Housekeeping',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 22)),
      assignedPersonnelIds: ['p3'],
      guestsAffected: 1,
      updates: [
        IncidentUpdate(
          id: _uuid.v4(),
          message: 'AED applied. Patient stabilising. EMS ETA 4 minutes.',
          authorName: 'Dr. Kim (On-call)',
          authorRole: 'Medical',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ],
    ),
    Incident(
      id: _uuid.v4(),
      type: IncidentType.security,
      severity: IncidentSeverity.high,
      status: IncidentStatus.inProgress,
      title: 'Unauthorised Access – Server Room',
      description: 'Door sensor triggered. CCTV shows unidentified individual near server room B2.',
      location: 'Basement Level B2',
      floor: -2,
      reportedBy: 'Security Camera Alert',
      reporterRole: 'System',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      assignedPersonnelIds: ['p1'],
      guestsAffected: 0,
    ),
    Incident(
      id: _uuid.v4(),
      type: IncidentType.utilityFailure,
      severity: IncidentSeverity.medium,
      status: IncidentStatus.inProgress,
      title: 'Power Failure – East Wing',
      description: 'Partial power loss affecting floors 6–8 east wing. Generator backup active.',
      location: 'Floors 6–8, East Wing',
      floor: 6,
      reportedBy: 'Building Management System',
      reporterRole: 'System',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 35)),
      assignedPersonnelIds: ['p5'],
      guestsAffected: 34,
    ),
    Incident(
      id: _uuid.v4(),
      type: IncidentType.evacuation,
      severity: IncidentSeverity.low,
      status: IncidentStatus.resolved,
      title: 'False Alarm – Sprinkler System Floor 3',
      description: 'Malfunctioning sprinkler triggered evacuation. Area cleared. System reset.',
      location: 'Floor 3 – Corridor B',
      floor: 3,
      reportedBy: 'Maintenance Staff',
      reporterRole: 'Maintenance',
      reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
      resolvedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      guestsAffected: 12,
    ),
  ];

  // ── Seed personnel ─────────────────────────────────────────────────────────
  List<Personnel> seedPersonnel() => [
    Personnel(id: 'p1', name: 'James Okafor',     role: PersonnelRole.security,     status: PersonnelStatus.deployed,  phone: '+1-555-0101', currentLocation: 'Ground Floor', avatarInitials: 'JO'),
    Personnel(id: 'p2', name: 'Priya Nair',        role: PersonnelRole.security,     status: PersonnelStatus.deployed,  phone: '+1-555-0102', currentLocation: 'Restaurant',   avatarInitials: 'PN'),
    Personnel(id: 'p3', name: 'Dr. Sarah Kim',     role: PersonnelRole.medical,      status: PersonnelStatus.deployed,  phone: '+1-555-0103', currentLocation: 'Room 412',     avatarInitials: 'SK'),
    Personnel(id: 'p4', name: 'Marcus Williams',   role: PersonnelRole.medical,      status: PersonnelStatus.available, phone: '+1-555-0104', currentLocation: 'Lobby',        avatarInitials: 'MW'),
    Personnel(id: 'p5', name: 'Elena Rodriguez',   role: PersonnelRole.maintenance,  status: PersonnelStatus.deployed,  phone: '+1-555-0105', currentLocation: 'Floor 6',      avatarInitials: 'ER'),
    Personnel(id: 'p6', name: 'Ahmed Hassan',      role: PersonnelRole.management,   status: PersonnelStatus.available, phone: '+1-555-0106', currentLocation: 'Control Room', avatarInitials: 'AH'),
    Personnel(id: 'p7', name: 'Chen Wei',          role: PersonnelRole.frontDesk,    status: PersonnelStatus.available, phone: '+1-555-0107', currentLocation: 'Front Desk',   avatarInitials: 'CW'),
    Personnel(id: 'p8', name: 'Fatima Al-Rashid',  role: PersonnelRole.housekeeping, status: PersonnelStatus.offDuty,   phone: '+1-555-0108', avatarInitials: 'FA'),
    Personnel(id: 'p9', name: 'Tom Nakamura',      role: PersonnelRole.security,     status: PersonnelStatus.available, phone: '+1-555-0109', currentLocation: 'Lobby',        avatarInitials: 'TN'),
    Personnel(id: 'p10', name: 'Lisa Park',        role: PersonnelRole.management,   status: PersonnelStatus.emergency, phone: '+1-555-0110', currentLocation: 'Command Room', avatarInitials: 'LP'),
  ];

  // ── Seed messages ──────────────────────────────────────────────────────────
  List<ChatMessage> seedMessages(MessageChannel channel) {
    final now = DateTime.now();
    final allMessages = <ChatMessage>[
      ChatMessage(
        id: _uuid.v4(),
        channel: MessageChannel.allStaff,
        senderId: 'system',
        senderName: 'CrisisSync',
        senderRole: 'System',
        content: '🚨 CRITICAL: Kitchen fire active. All available staff to emergency stations.',
        priority: MessagePriority.critical,
        timestamp: now.subtract(const Duration(minutes: 8)),
        isSystemMessage: true,
      ),
      ChatMessage(
        id: _uuid.v4(),
        channel: MessageChannel.security,
        senderId: 'p1',
        senderName: 'James Okafor',
        senderRole: 'Security',
        content: 'Deployed to ground floor. Restaurant guests being moved to lobby.',
        priority: MessagePriority.urgent,
        timestamp: now.subtract(const Duration(minutes: 6)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        channel: MessageChannel.medical,
        senderId: 'p3',
        senderName: 'Dr. Sarah Kim',
        senderRole: 'Medical',
        content: 'AED applied. Patient stabilising. Need clear path for paramedics – elevator B.',
        priority: MessagePriority.critical,
        timestamp: now.subtract(const Duration(minutes: 14)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        channel: MessageChannel.management,
        senderId: 'p10',
        senderName: 'Lisa Park',
        senderRole: 'Management',
        content: 'Coordinating with GM. Evacuating restaurant wing. Media blackout in effect.',
        priority: MessagePriority.urgent,
        timestamp: now.subtract(const Duration(minutes: 7)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        channel: MessageChannel.guestAlert,
        senderId: 'p6',
        senderName: 'Ahmed Hassan',
        senderRole: 'Management',
        content: 'Attention guests: a situation in the restaurant is being resolved. Please remain in your rooms or proceed to the lobby for assistance.',
        priority: MessagePriority.normal,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        channel: MessageChannel.allStaff,
        senderId: 'p2',
        senderName: 'Priya Nair',
        senderRole: 'Security',
        content: 'Restaurant cleared. Fire brigade arriving in 3 minutes. Keep lobby entrance open.',
        priority: MessagePriority.urgent,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    ];
    return allMessages.where((m) => m.channel == channel).toList();
  }

  // ── Live event injection (simulates real-time updates) ─────────────────────
  StreamController<Incident>? _incidentController;

  Stream<Incident> liveIncidentStream() {
    _incidentController = StreamController<Incident>.broadcast();
    Timer.periodic(const Duration(seconds: 45), (_) => _injectRandomEvent());
    return _incidentController!.stream;
  }

  void _injectRandomEvent() {
    if (_incidentController == null || !_incidentController!.hasListener) return;
    final types = IncidentType.values;
    final severities = [IncidentSeverity.low, IncidentSeverity.medium, IncidentSeverity.high];
    final locations = ['Lobby', 'Pool Area', 'Gym', 'Conference Room A', 'Parking Level B1', 'Rooftop Bar'];
    final incident = Incident(
      id: _uuid.v4(),
      type: types[_rng.nextInt(types.length)],
      severity: severities[_rng.nextInt(severities.length)],
      status: IncidentStatus.reported,
      title: 'New Alert – ${locations[_rng.nextInt(locations.length)]}',
      description: 'Automated sensor detection. Awaiting staff confirmation.',
      location: locations[_rng.nextInt(locations.length)],
      floor: _rng.nextInt(10),
      reportedBy: 'Sensor System',
      reporterRole: 'System',
      reportedAt: DateTime.now(),
    );
    _incidentController!.add(incident);
  }

  void dispose() {
    _incidentController?.close();
    _incidentController = null;
  }
}
