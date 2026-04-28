import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/message.dart';
import '../../core/providers/comms_provider.dart';
import '../../core/services/n8n_service.dart';
import '../../shared/widgets/glass_card.dart';

class CommsScreen extends StatefulWidget {
  const CommsScreen({super.key});
  @override
  State<CommsScreen> createState() => _CommsScreenState();
}

class _CommsScreenState extends State<CommsScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  MessagePriority _priority = MessagePriority.normal;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(CommsProvider comms) {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    comms.sendMessage(ChatMessage(
      id: const Uuid().v4(),
      channel: comms.activeChannel,
      senderId: 'user',
      senderName: 'Command Center',
      senderRole: 'Management',
      content: text,
      priority: _priority,
      timestamp: DateTime.now(),
    ));
    _msgCtrl.clear();
    _priority = MessagePriority.normal;
    Future.delayed(100.ms, () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: 200.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer<CommsProvider>(builder: (_, comms, __) {
        final messages = comms.messages;
        return Row(children: [
          // Channel sidebar
          Container(width: 200, color: AppColors.bgSecondary,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Channels', style: AppTextStyles.titleMedium)),
              const Divider(height: 1),
              Expanded(child: ListView(children: MessageChannel.values.map((ch) {
                final active = ch == comms.activeChannel;
                final count = comms.unreadCount(ch);
                return Material(color: Colors.transparent, child: InkWell(
                  onTap: () => comms.switchChannel(ch),
                  child: AnimatedContainer(duration: 150.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: active ? AppColors.accentBlue.withOpacity(0.1) : Colors.transparent,
                    child: Row(children: [
                      Text(ch.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ch.label, style: AppTextStyles.bodyMedium.copyWith(
                        color: active ? AppColors.accentBlue : AppColors.textSecondary,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
                      if (count > 0) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.2),
                          borderRadius: AppRadius.full),
                        child: Text('$count', style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentBlue, fontSize: 10)),
                      ),
                    ]),
                  ),
                ));
              }).toList())),
            ]),
          ),
          Container(width: 1, color: AppColors.glassBorder),
          // Messages
          Expanded(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
              decoration: const BoxDecoration(color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                Text(comms.activeChannel.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(comms.activeChannel.label, style: AppTextStyles.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.language_rounded, color: AppColors.accentIndigo),
                  tooltip: 'Global Broadcast (WhatsApp, Slack, Gmail)',
                  onPressed: () => _showBroadcastDialog(context),
                ),
                const SizedBox(width: 8),
                Text('${messages.length} messages', style: AppTextStyles.bodyMedium),
              ]),
            ),
            // Message list
            Expanded(child: messages.isEmpty
              ? Center(child: Text('No messages yet', style: AppTextStyles.bodyMedium))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MsgBubble(msg: messages[i], index: i),
                )),
            // Composer
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(color: AppColors.bgSecondary,
                border: Border(top: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                // Priority toggle
                PopupMenuButton<MessagePriority>(
                  icon: Icon(_priorityIcon(_priority), color: _priorityColor(_priority), size: 20),
                  color: AppColors.bgElevated,
                  itemBuilder: (_) => MessagePriority.values.map((p) =>
                    PopupMenuItem(value: p, child: Row(children: [
                      Icon(_priorityIcon(p), color: _priorityColor(p), size: 16),
                      const SizedBox(width: 8),
                      Text(p.label, style: AppTextStyles.bodyMedium),
                    ]))).toList(),
                  onSelected: (p) => setState(() => _priority = p),
                ),
                const SizedBox(width: 4),
                Expanded(child: TextField(
                  controller: _msgCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.glassBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(comms),
                )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.accentBlue),
                  onPressed: () => _send(comms),
                ),
              ]),
            ),
          ])),
        ]);
      }),
    );
  }

  IconData _priorityIcon(MessagePriority p) => switch (p) {
    MessagePriority.normal   => Icons.remove_circle_outline,
    MessagePriority.urgent   => Icons.warning_amber_rounded,
    MessagePriority.critical => Icons.error_rounded,
  };

  Color _priorityColor(MessagePriority p) => switch (p) {
    MessagePriority.normal   => AppColors.textMuted,
    MessagePriority.urgent   => AppColors.crisisAmber,
    MessagePriority.critical => AppColors.crisisRed,
  };

  void _showBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('Global Broadcast', style: AppTextStyles.titleLarge),
        content: Text(
          'This will send a real-time alert via n8n to:\n'
          '• WhatsApp (via Twilio/Cloud API)\n'
          '• Slack (Crisis Channel)\n'
          '• Gmail (Emergency Distribution List)',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentIndigo),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await N8nIntegrationService.instance.broadcastToExternalChannels(
                incidentTitle: 'System-Wide Emergency Alert',
                description: 'A high-severity incident requires immediate attention. Check CrisisSync EOC.',
                severity: 'critical',
                channels: ['whatsapp', 'slack', 'gmail'],
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Global Broadcast Sent!' : 'Failed to reach n8n bridge'),
                  backgroundColor: success ? AppColors.crisisGreen : AppColors.crisisRed,
                ));
              }
            },
            child: const Text('SEND NOW'),
          ),
        ],
      ),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  const _MsgBubble({required this.msg, required this.index});
  final ChatMessage msg;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isSelf = msg.senderId == 'user';
    final isSystem = msg.isSystemMessage;
    final prColor = switch (msg.priority) {
      MessagePriority.critical => AppColors.crisisRed,
      MessagePriority.urgent   => AppColors.crisisAmber,
      _                        => null,
    };

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (prColor ?? AppColors.accentBlue).withOpacity(0.1),
          borderRadius: AppRadius.md,
          border: Border.all(color: (prColor ?? AppColors.accentBlue).withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(Icons.campaign_rounded, color: prColor ?? AppColors.accentBlue, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg.content, style: AppTextStyles.bodyMedium.copyWith(
              color: prColor ?? AppColors.accentBlue))),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 30 * index));
    }

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelf ? AppColors.accentBlue.withOpacity(0.15) : AppColors.bgElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12), topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isSelf ? 12 : 4),
            bottomRight: Radius.circular(isSelf ? 4 : 12),
          ),
          border: prColor != null ? Border.all(color: prColor.withOpacity(0.4)) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(msg.senderName, style: AppTextStyles.labelLarge.copyWith(fontSize: 11,
                color: isSelf ? AppColors.accentBlue : AppColors.textPrimary)),
            const SizedBox(width: 6),
            Text(msg.senderRole, style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
          ]),
          const SizedBox(height: 4),
          Text(msg.content, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(DateFormat('HH:mm').format(msg.timestamp), style: AppTextStyles.labelSmall),
        ]),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 30 * index)).slideY(begin: 0.05, end: 0);
  }
}
