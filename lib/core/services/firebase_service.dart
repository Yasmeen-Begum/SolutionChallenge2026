import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/incident.dart';
import '../models/personnel.dart';
import '../models/message.dart';

/// Abstracts all Firebase Firestore + Cloud Messaging interactions.
/// Providers consume this service; they never touch Firebase directly.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _db  = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  // ── Collection references ─────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _incidents  => _db.collection('incidents');
  CollectionReference<Map<String, dynamic>> get _personnel  => _db.collection('personnel');
  CollectionReference<Map<String, dynamic>> _messages(MessageChannel ch) =>
      _db.collection('messages').doc(ch.name).collection('chats');

  // ── FCM setup ─────────────────────────────────────────────────────────────
  Future<void> initFcm() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final token = await _fcm.getToken();
    if (token != null) {
      // In production: save token to Firestore under current user doc
    }
  }

  // ── Incidents ─────────────────────────────────────────────────────────────
  Stream<List<Incident>> incidentsStream() {
    return _incidents
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Incident.fromFirestore).toList());
  }

  Future<String> addIncident(Incident incident) async {
    final ref = await _incidents.add(incident.toFirestore());
    return ref.id;
  }

  Future<void> updateIncidentStatus(String id, IncidentStatus status) async {
    await _incidents.doc(id).update({'status': status.name});
  }

  Future<void> addIncidentUpdate(String incidentId, IncidentUpdate update) async {
    await _incidents.doc(incidentId).update({
      'updates': FieldValue.arrayUnion([update.toMap()]),
    });
  }

  Future<void> assignPersonnel(String incidentId, String personnelId) async {
    await _incidents.doc(incidentId).update({
      'assignedPersonnelIds': FieldValue.arrayUnion([personnelId]),
    });
  }

  // ── Personnel ─────────────────────────────────────────────────────────────
  Stream<List<Personnel>> personnelStream() {
    return _personnel
        .snapshots()
        .map((snap) => snap.docs.map(Personnel.fromFirestore).toList());
  }

  Future<void> updatePersonnelStatus(String id, PersonnelStatus status) async {
    await _personnel.doc(id).update({'status': status.name});
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  Stream<List<ChatMessage>> messagesStream(MessageChannel channel) {
    return _messages(channel)
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _messages(message.channel).doc(message.id).set(message.toFirestore());
  }
}
