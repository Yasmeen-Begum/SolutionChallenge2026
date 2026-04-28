import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/demo_service.dart';

class CommsProvider extends ChangeNotifier {
  CommsProvider({required DemoService demoService}) : _demo = demoService;

  final DemoService _demo;

  MessageChannel _activeChannel = MessageChannel.allStaff;
  final Map<MessageChannel, List<ChatMessage>> _messages = {};
  bool _isLoading = true;

  // ── Getters ──────────────────────────────────────────────────────────────
  MessageChannel get activeChannel => _activeChannel;
  bool get isLoading => _isLoading;

  List<ChatMessage> get messages =>
      _messages[_activeChannel] ?? [];

  List<ChatMessage> allMessages() {
    final all = <ChatMessage>[];
    for (final msgs in _messages.values) all.addAll(msgs);
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  int unreadCount(MessageChannel channel) =>
      (_messages[channel] ?? []).length;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _isLoading = true;
    for (final ch in MessageChannel.values) {
      _messages[ch] = _demo.seedMessages(ch);
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void switchChannel(MessageChannel channel) {
    _activeChannel = channel;
    notifyListeners();
  }

  Future<void> sendMessage(ChatMessage message) async {
    final list = _messages[message.channel] ?? [];
    _messages[message.channel] = [...list, message];
    notifyListeners();
  }

  Future<void> broadcastAlert({
    required String content,
    required MessagePriority priority,
    required String senderName,
    required String senderRole,
  }) async {
    for (final channel in MessageChannel.values) {
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        channel: channel,
        senderId: 'broadcast',
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        priority: priority,
        timestamp: DateTime.now(),
        isSystemMessage: priority == MessagePriority.critical,
      );
      final list = _messages[channel] ?? [];
      _messages[channel] = [...list, msg];
    }
    notifyListeners();
  }
}
