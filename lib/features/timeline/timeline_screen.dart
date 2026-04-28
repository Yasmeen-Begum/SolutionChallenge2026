import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/incident.dart';
import '../../core/providers/crisis_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/severity_badge.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  IncidentStatus? _filterStatus;
  IncidentSeverity? _filterSeverity;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer<CrisisProvider>(
        builder: (_, cp, __) {
          var incidents = cp.incidents;
          if (_filterStatus != null) {
            incidents = incidents.where((i) => i.status == _filterStatus).toList();
          }
          if (_filterSeverity != null) {
            incidents = incidents.where((i) => i.severity == _filterSeverity).toList();
          }

          final selected = _selectedId != null ? cp.findById(_selectedId!) : null;

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _FilterBar(
                      status: _filterStatus,
                      severity: _filterSeverity,
                      onStatusChanged: (s) => setState(() => _filterStatus = s),
                      onSeverityChanged: (s) => setState(() => _filterSeverity = s),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: incidents.length,
                        itemBuilder: (_, i) => _IncidentCard(
                          incident: incidents[i],
                          isSelected: incidents[i].id == _selectedId,
                          onTap: () => setState(() => _selectedId = incidents[i].id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected != null)
                Container(
                  width: 1,
                  color: AppColors.glassBorder,
                ),
              if (selected != null)
                Expanded(
                  flex: 3,
                  child: _DetailPanel(
                    incident: selected,
                    cp: cp,
                    onClose: () => setState(() => _selectedId = null),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.severity,
    required this.onStatusChanged,
    required this.onSeverityChanged,
  });
  final IncidentStatus? status;
  final IncidentSeverity? severity;
  final ValueChanged<IncidentStatus?> onStatusChanged;
  final ValueChanged<IncidentSeverity?> onSeverityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Text('Incident Timeline', style: AppTextStyles.titleMedium),
          const Spacer(),
          DropdownButton<IncidentStatus?>(
            value: status,
            dropdownColor: AppColors.bgElevated,
            style: AppTextStyles.bodyMedium,
            hint: Text('All Status', style: AppTextStyles.bodyMedium),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Status')),
              ...IncidentStatus.values.map((s) =>
                  DropdownMenuItem(value: s, child: Text(s.label))),
            ],
            onChanged: onStatusChanged,
            underline: const SizedBox(),
          ),
          const SizedBox(width: 12),
          DropdownButton<IncidentSeverity?>(
            value: severity,
            dropdownColor: AppColors.bgElevated,
            style: AppTextStyles.bodyMedium,
            hint: Text('All Severity', style: AppTextStyles.bodyMedium),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Severity')),
              ...IncidentSeverity.values.map((s) =>
                  DropdownMenuItem(value: s, child: Text(s.label))),
            ],
            onChanged: onSeverityChanged,
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.isSelected,
    required this.onTap,
  });
  final Incident incident;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSeverity(incident.severity.name);
    final timeAgo = _ago(incident.reportedAt);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 150.ms,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withOpacity(0.1) : AppColors.bgCard,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : color.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(color: color, borderRadius: AppRadius.full),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(incident.type.icon),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(incident.title,
                            style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${incident.location} • $timeAgo',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SeverityBadge(incident.severity, small: true),
                const SizedBox(height: 4),
                StatusBadge(incident.status.label,
                    color: AppColors.forStatus(incident.status.name)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.04, end: 0);
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.incident,
    required this.cp,
    required this.onClose,
  });
  final Incident incident;
  final CrisisProvider cp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSeverity(incident.severity.name);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(child: Text('Incident Detail', style: AppTextStyles.titleLarge)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          borderColor: color.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(incident.type.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(incident.title, style: AppTextStyles.titleLarge)),
                ],
              ),
              const SizedBox(height: 12),
              Text(incident.description, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              _InfoRow('Location', incident.location),
              _InfoRow('Floor',    'Floor ${incident.floor}'),
              if (incident.roomNumber != null)
                _InfoRow('Room', incident.roomNumber!),
              _InfoRow('Reported by', '${incident.reportedBy} (${incident.reporterRole})'),
              _InfoRow('Reported at', DateFormat('HH:mm, d MMM').format(incident.reportedAt)),
              _InfoRow('Guests affected', '${incident.guestsAffected}'),
              const SizedBox(height: 12),
              Row(children: [
                SeverityBadge(incident.severity),
                const SizedBox(width: 8),
                StatusBadge(incident.status.label,
                    color: AppColors.forStatus(incident.status.name)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Status workflow buttons
        if (incident.status != IncidentStatus.resolved)
          Row(
            children: [
              if (incident.status == IncidentStatus.reported)
                Expanded(child: _StatusBtn('Acknowledge', IncidentStatus.active, AppColors.crisisAmber, incident.id, cp)),
              if (incident.status == IncidentStatus.active)
                Expanded(child: _StatusBtn('In Progress', IncidentStatus.inProgress, AppColors.accentBlue, incident.id, cp)),
              if (incident.status == IncidentStatus.inProgress) ...[
                const SizedBox(width: 8),
                Expanded(child: _StatusBtn('Resolve', IncidentStatus.resolved, AppColors.crisisGreen, incident.id, cp)),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        // Timeline
        Text('Activity Timeline', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: incident.updates.isEmpty
                ? [Text('No updates yet.', style: AppTextStyles.bodyMedium)]
                : incident.updates.asMap().entries.map((e) {
                    final u = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentBlue.withOpacity(0.15),
                                  border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.update_rounded,
                                    color: AppColors.accentBlue, size: 14),
                              ),
                              if (e.key < incident.updates.length - 1)
                                Container(width: 2, height: 24, color: AppColors.glassBorder),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(u.authorName,
                                        style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text('• ${u.authorRole}',
                                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
                                  ],
                                ),
                                Text(u.message, style: AppTextStyles.bodyMedium),
                                Text(DateFormat('HH:mm').format(u.timestamp),
                                    style: AppTextStyles.labelSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyLarge.copyWith(fontSize: 14))),
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  const _StatusBtn(this.label, this.status, this.color, this.incidentId, this.cp);
  final String label;
  final IncidentStatus status;
  final Color color;
  final String incidentId;
  final CrisisProvider cp;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () => cp.updateStatus(incidentId, status),
      child: Text(label),
    );
  }
}
