import 'package:flutter/foundation.dart';
import '../models/personnel.dart';
import '../services/demo_service.dart';

class PersonnelProvider extends ChangeNotifier {
  PersonnelProvider({required DemoService demoService}) : _demo = demoService;

  final DemoService _demo;
  List<Personnel> _personnel = [];
  bool _isLoading = true;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<Personnel> get personnel => _personnel;
  bool get isLoading => _isLoading;

  List<Personnel> byRole(PersonnelRole role) =>
      _personnel.where((p) => p.role == role).toList();

  List<Personnel> byStatus(PersonnelStatus status) =>
      _personnel.where((p) => p.status == status).toList();

  int get availableCount =>
      _personnel.where((p) => p.status == PersonnelStatus.available).length;

  int get deployedCount =>
      _personnel.where((p) => p.status == PersonnelStatus.deployed).length;

  double get avgResponseTime {
    if (_personnel.isEmpty) return 0;
    return _personnel.fold(0.0, (s, p) => s + p.avgResponseMinutes) / _personnel.length;
  }

  Map<PersonnelRole, int> get roleDistribution {
    final map = <PersonnelRole, int>{};
    for (final role in PersonnelRole.values) {
      map[role] = _personnel.where((p) => p.role == role).length;
    }
    return map;
  }

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _isLoading = true;
    _personnel = _demo.seedPersonnel();
    _isLoading = false;
    notifyListeners();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> updateStatus(String id, PersonnelStatus status) async {
    _personnel = _personnel.map((p) {
      if (p.id != id) return p;
      return p.copyWith(status: status);
    }).toList();
    notifyListeners();
  }

  Future<void> assignToIncident(String personnelId, String incidentId) async {
    _personnel = _personnel.map((p) {
      if (p.id != personnelId) return p;
      return p.copyWith(
        status: PersonnelStatus.deployed,
        assignedIncidentId: incidentId,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> releaseFromIncident(String personnelId) async {
    _personnel = _personnel.map((p) {
      if (p.id != personnelId) return p;
      return p.copyWith(
        status: PersonnelStatus.available,
        assignedIncidentId: null,
      );
    }).toList();
    notifyListeners();
  }

  Personnel? findById(String id) =>
      _personnel.cast<Personnel?>().firstWhere((p) => p?.id == id, orElse: () => null);
}
