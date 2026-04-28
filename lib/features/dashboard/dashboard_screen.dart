import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/crisis_provider.dart';
import '../../core/providers/personnel_provider.dart';
import '../../core/providers/comms_provider.dart';
import '../../core/models/incident.dart';
import '../../core/models/message.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/severity_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer3<CrisisProvider, PersonnelProvider, CommsProvider>(
        builder: (_, cp, pp, comms, __) {
          if (cp.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _Header(),
              const SizedBox(height: AppSpacing.md),
              _KpiRow(cp: cp, pp: pp),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _IncidentFeed(cp: cp)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 2, child: Column(
                    children: [
                      _SeverityChart(cp: cp),
                      const SizedBox(height: AppSpacing.md),
                      _QuickActions(cp: cp, comms: comms),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RecentComms(comms: comms),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateFormat('EEEE, d MMM yyyy  •  HH:mm').format(DateTime.now());
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Command Center', style: AppTextStyles.headlineLarge),
            Text(now, style: AppTextStyles.bodyMedium),
          ],
        ),
        const Spacer(),
        Consumer<CrisisProvider>(
          builder: (_, cp, __) {
            final level = cp.threatLevel;
            final color = level == ThreatLevel.critical
                ? AppColors.crisisRed
                : level == ThreatLevel.elevated
                    ? AppColors.crisisAmber
                    : AppColors.crisisGreen;
            final label = level.name.toUpperCase();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: AppRadius.full,
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  PulseIndicator(color: color, size: 8),
                  const SizedBox(width: 8),
                  Text('THREAT: $label',
                      style: AppTextStyles.labelLarge.copyWith(color: color)),
                ],
              ),
            ).animate(onPlay: (c) => level == ThreatLevel.critical ? c.repeat() : null)
              .shimmer(duration: 1500.ms, color: color.withOpacity(0.3));
          },
        ),
      ],
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.cp, required this.pp});
  final CrisisProvider cp;
  final PersonnelProvider pp;

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiData('Active Incidents',  '${cp.active.length}',     Icons.warning_amber_rounded,  AppColors.crisisRed),
      _KpiData('Staff Deployed',    '${pp.deployedCount}',     Icons.people_rounded,          AppColors.crisisAmber),
      _KpiData('Guests Affected',   '${cp.totalGuestsAffected}', Icons.group_rounded,         AppColors.accentBlue),
      _KpiData('Avg Response',      '${pp.avgResponseTime.toStringAsFixed(1)}m', Icons.timer_rounded, AppColors.crisisGreen),
    ];

    return Row(
      children: kpis
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < kpis.length - 1 ? AppSpacing.sm : 0),
                  child: _KpiCard(data: e.value),
                ),
              ))
          .toList(),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.15),
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, color: AppColors.crisisGreen, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.value,
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 28,
                color: data.color,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          Text(data.label, style: AppTextStyles.bodyMedium),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Incident Feed ─────────────────────────────────────────────────────────────
class _IncidentFeed extends StatelessWidget {
  const _IncidentFeed({required this.cp});
  final CrisisProvider cp;

  @override
  Widget build(BuildContext context) {
    final incidents = cp.incidents.take(6).toList();
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Live Incident Feed', style: AppTextStyles.titleMedium),
              const Spacer(),
              if (cp.active.isNotEmpty)
                PulseIndicator(color: AppColors.crisisRed, size: 6),
              if (cp.active.isNotEmpty) const SizedBox(width: 6),
              Text('${cp.active.length} active',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.crisisRed)),
            ],
          ),
          const SizedBox(height: 12),
          ...incidents.asMap().entries.map((e) =>
            _IncidentTile(incident: e.value, index: e.key),
          ),
        ],
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident, required this.index});
  final Incident incident;
  final int index;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.forStatus(incident.status.name);
    final timeDiff = DateTime.now().difference(incident.reportedAt);
    final timeAgo = timeDiff.inMinutes < 60
        ? '${timeDiff.inMinutes}m ago'
        : '${timeDiff.inHours}h ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: incident.severity == IncidentSeverity.critical
            ? [BoxShadow(color: AppColors.crisisRed.withOpacity(0.15), blurRadius: 8)]
            : null,
      ),
      child: Row(
        children: [
          Text(incident.type.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incident.title,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${incident.location} • $timeAgo',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SeverityBadge(incident.severity, small: true),
              const SizedBox(height: 4),
              StatusBadge(incident.status.label, color: statusColor),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: -0.05, end: 0);
  }
}

// ── Severity Chart (simple bar) ───────────────────────────────────────────────
class _SeverityChart extends StatelessWidget {
  const _SeverityChart({required this.cp});
  final CrisisProvider cp;

  @override
  Widget build(BuildContext context) {
    final dist = cp.severityDistribution;
    final max = dist.values.fold(0, (a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Severity Distribution', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          ...IncidentSeverity.values.map((sev) {
            final count = dist[sev] ?? 0;
            final color = AppColors.forSeverity(sev.name);
            final pct = max == 0 ? 0.0 : count / max;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(sev.label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.full,
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count', style: AppTextStyles.labelLarge.copyWith(color: color)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.cp, required this.comms});
  final CrisisProvider cp;
  final CommsProvider comms;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          _ActionBtn('🔒 Initiate Lockdown',    AppColors.crisisRed,    () => _confirm(context, 'Initiate Lockdown', comms)),
          _ActionBtn('🚪 Broadcast Evacuation', AppColors.crisisAmber,  () => _confirm(context, 'Broadcast Evacuation', comms)),
          _ActionBtn('🚨 Alert First Responders', AppColors.accentBlue, () => _confirm(context, 'Alert First Responders', comms)),
          _ActionBtn('✅ All Clear',             AppColors.crisisGreen,  () => _confirm(context, 'All Clear', comms)),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String action, CommsProvider comms) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('Confirm: $action', style: AppTextStyles.titleMedium),
        content: Text('This will broadcast a "$action" alert to all channels.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crisisRed),
            onPressed: () {
              comms.broadcastAlert(
                content: '🚨 $action activated by Command Center.',
                priority: MessagePriority.critical,
                senderName: 'Command Center',
                senderRole: 'System',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$action broadcast sent to all channels'),
                  backgroundColor: AppColors.bgElevated,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.5)),
            backgroundColor: color.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap,
          child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
        ),
      ),
    );
  }
}

// ── Recent Comms ──────────────────────────────────────────────────────────────
class _RecentComms extends StatelessWidget {
  const _RecentComms({required this.comms});
  final CommsProvider comms;

  @override
  Widget build(BuildContext context) {
    final recent = comms.allMessages().take(3).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Communications', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...recent.map((msg) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accentBlue.withOpacity(0.2),
                  child: Text(msg.senderName[0],
                      style: const TextStyle(fontSize: 12, color: AppColors.accentBlue)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(msg.senderName,
                              style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text('• ${msg.channel.label}',
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
                        ],
                      ),
                      Text(msg.content,
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
