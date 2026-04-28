import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../services/demo_service.dart';
import '../services/n8n_service.dart';

enum ThreatLevel { normal, elevated, critical }

class CrisisProvider extends ChangeNotifier {
  CrisisProvider({required DemoService demoService}) : _demo = demoService;

  final DemoService _demo;
  StreamSubscription<Incident>? _liveStream;

  List<Incident> _incidents = [];
  bool _isLoading = true;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Incident> get active => _incidents
      .where((i) => i.status == IncidentStatus.active || i.status == IncidentStatus.inProgress)
      .toList();

  List<Incident> get resolved => _incidents
      .where((i) => i.status == IncidentStatus.resolved)
      .toList();

  int get totalGuestsAffected =>
      _incidents.fold(0, (sum, i) => sum + i.guestsAffected);

  ThreatLevel get threatLevel {
    if (_incidents.any((i) =>
        i.severity == IncidentSeverity.critical &&
        i.status != IncidentStatus.resolved)) return ThreatLevel.critical;
    if (_incidents.any((i) =>
        i.severity == IncidentSeverity.high &&
        i.status != IncidentStatus.resolved)) return ThreatLevel.elevated;
    return ThreatLevel.normal;
  }

  Map<IncidentSeverity, int> get severityDistribution {
    final map = <IncidentSeverity, int>{};
    for (final sev in IncidentSeverity.values) {
      map[sev] = _incidents.where((i) => i.severity == sev).length;
    }
    return map;
  }

  Map<IncidentType, int> get typeDistribution {
    final map = <IncidentType, int>{};
    for (final type in IncidentType.values) {
      map[type] = _incidents.where((i) => i.type == type).length;
    }
    return map;
  }

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _incidents = _demo.seedIncidents();
      _isLoading = false;
      notifyListeners();
      _liveStream = _demo.liveIncidentStream().listen(_onLiveIncident);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onLiveIncident(Incident incident) {
    _incidents = [incident, ..._incidents];
    
    // Auto-trigger external alerts for Critical incidents
    if (incident.severity == IncidentSeverity.critical) {
      N8nIntegrationService.instance.broadcastToExternalChannels(
        incidentTitle: incident.title,
        description: incident.description,
        severity: 'critical',
        channels: ['whatsapp', 'gmail', 'slack'],
      );
    }
    
    notifyListeners();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> addIncident(Incident incident) async {
    _incidents = [incident, ..._incidents];
    
    // Auto-trigger external alerts for Critical incidents
    if (incident.severity == IncidentSeverity.critical) {
      N8nIntegrationService.instance.broadcastToExternalChannels(
        incidentTitle: incident.title,
        description: incident.description,
        severity: 'critical',
        channels: ['whatsapp', 'gmail', 'slack'],
      );
    }
    
    notifyListeners();
  }

  Future<void> updateStatus(String id, IncidentStatus status) async {
    _incidents = _incidents.map((i) {
      if (i.id != id) return i;
      return i.copyWith(
        status: status,
        resolvedAt: status == IncidentStatus.resolved ? DateTime.now() : null,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> assignPersonnel(String incidentId, String personnelId) async {
    _incidents = _incidents.map((i) {
      if (i.id != incidentId) return i;
      final ids = [...i.assignedPersonnelIds, personnelId];
      return i.copyWith(assignedPersonnelIds: ids);
    }).toList();
    notifyListeners();
  }

  Future<void> addUpdate(String incidentId, IncidentUpdate update) async {
    _incidents = _incidents.map((i) {
      if (i.id != incidentId) return i;
      return i.copyWith(updates: [...i.updates, update]);
    }).toList();
    notifyListeners();
  }

  Incident? findById(String id) =>
      _incidents.cast<Incident?>().firstWhere((i) => i?.id == id, orElse: () => null);

  @override
  void dispose() {
    _liveStream?.cancel();
    _demo.dispose();
    super.dispose();
  }
}
