import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/message.dart';
import '../../core/services/gemma_service.dart';
import '../../shared/widgets/glass_card.dart';

class AiAssistScreen extends StatefulWidget {
  const AiAssistScreen({super.key});
  @override
  State<AiAssistScreen> createState() => _AiAssistScreenState();
}

class _AiAssistScreenState extends State<AiAssistScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <AiMessage>[];
  bool _loading = false;

  final _quickPrompts = [
    '🔥 Fire in the kitchen – action plan',
    '🏥 Guest medical emergency protocol',
    '🔒 Security breach response steps',
    '🚪 Building evacuation checklist',
    '⚡ Power failure contingency plan',
    '📋 Post-incident report template',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(AiMessage(
      content: '👋 **Welcome to CrisisSync AI Assistant**\n\n'
          'I\'m powered by **Gemma 4** and specialised in hospitality emergency response.\n\n'
          'I can help you with:\n'
          '• Real-time incident analysis & action plans\n'
          '• Personnel deployment recommendations\n'
          '• Guest communication drafting\n'
          '• Evacuation route guidance\n'
          '• Post-incident review\n\n'
          'Ask me anything or use a quick prompt below.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(AiMessage(content: text, isUser: true, timestamp: DateTime.now()));
      _loading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    final reply = await GemmaService.instance.chat(text);

    setState(() {
      _messages.add(AiMessage(content: reply, isUser: false, timestamp: DateTime.now()));
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(100.ms, () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: 250.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: const BoxDecoration(color: AppColors.bgSecondary,
            border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentBlue, AppColors.accentIndigo]),
                borderRadius: AppRadius.sm),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Crisis Assistant', style: AppTextStyles.titleMedium),
              Text('Powered by Gemma 4 • HuggingFace', style: AppTextStyles.labelSmall),
            ]),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              onPressed: () => setState(() {
                GemmaService.instance.clearHistory();
                _messages.clear();
                _messages.add(AiMessage(
                  content: 'Conversation cleared. How can I help?',
                  isUser: false, timestamp: DateTime.now()));
              }),
            ),
          ]),
        ),
        // Quick prompts
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: AppColors.bgSecondary,
          child: ListView(scrollDirection: Axis.horizontal,
            children: _quickPrompts.map((p) => Padding(
              padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTextStyles.labelSmall.copyWith(fontSize: 11)),
                onPressed: () => _send(p),
                child: Text(p),
              ),
            )).toList(),
          ),
        ),
        // Messages
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: _messages.length + (_loading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _messages.length) return _TypingIndicator();
            return _ChatBubble(msg: _messages[i], index: i);
          },
        )),
        // Input
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(color: AppColors.bgSecondary,
            border: Border(top: BorderSide(color: AppColors.glassBorder))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              style: AppTextStyles.bodyLarge,
              maxLines: 3, minLines: 1,
              decoration: InputDecoration(
                hintText: 'Describe the crisis situation...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.glassBorder)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              onSubmitted: _send,
            )),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentBlue, AppColors.accentIndigo]),
                borderRadius: BorderRadius.circular(20)),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () => _send(_ctrl.text),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg, required this.index});
  final AiMessage msg;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentBlue.withOpacity(0.15) : AppColors.bgElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16)),
          border: Border.all(color: isUser
              ? AppColors.accentBlue.withOpacity(0.3)
              : AppColors.glassBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isUser ? Icons.person : Icons.auto_awesome,
                size: 14,
                color: isUser ? AppColors.accentBlue : AppColors.accentIndigo),
            const SizedBox(width: 6),
            Text(isUser ? 'You' : 'CrisisSync AI',
                style: AppTextStyles.labelLarge.copyWith(fontSize: 11,
                    color: isUser ? AppColors.accentBlue : AppColors.accentIndigo)),
            const Spacer(),
            Text(DateFormat('HH:mm').format(msg.timestamp),
                style: AppTextStyles.labelSmall),
          ]),
          const SizedBox(height: 8),
          Text(msg.content, style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary, height: 1.5)),
        ]),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.05);
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgElevated, borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.glassBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(width: 8, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.accentIndigo),
            ).animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.2, 1.2),
                  delay: Duration(milliseconds: 200 * i), duration: 400.ms)
              .then().scale(begin: const Offset(1.2, 1.2), end: const Offset(0.6, 0.6),
                  duration: 400.ms),
          const SizedBox(width: 8),
          Text('Analysing...', style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentIndigo)),
        ]),
      ),
    );
  }
}
