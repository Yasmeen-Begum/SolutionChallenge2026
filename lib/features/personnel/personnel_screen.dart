import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/personnel.dart';
import '../../core/providers/personnel_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/severity_badge.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});
  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  PersonnelRole? _filterRole;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer<PersonnelProvider>(builder: (_, pp, __) {
        var staff = pp.personnel;
        if (_filterRole != null) staff = staff.where((p) => p.role == _filterRole).toList();
        if (_search.isNotEmpty) staff = staff.where((p) =>
            p.name.toLowerCase().contains(_search.toLowerCase())).toList();

        return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
          Text('Personnel Tracker', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text('Manage staff deployment and status', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          // Overview cards
          Row(children: [
            _StatCard('Total Staff', '${pp.personnel.length}', Icons.people, AppColors.accentBlue),
            const SizedBox(width: 8),
            _StatCard('Available', '${pp.availableCount}', Icons.check_circle, AppColors.crisisGreen),
            const SizedBox(width: 8),
            _StatCard('Deployed', '${pp.deployedCount}', Icons.directions_run, AppColors.crisisAmber),
            const SizedBox(width: 8),
            _StatCard('Avg Response', '${pp.avgResponseTime.toStringAsFixed(1)}m', Icons.timer, AppColors.accentIndigo),
          ].map((w) => Expanded(child: w)).toList()),
          const SizedBox(height: AppSpacing.md),
          // Team overview
          Text('Teams', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          SizedBox(height: 80, child: ListView(scrollDirection: Axis.horizontal,
            children: PersonnelRole.values.map((role) {
              final count = pp.byRole(role).length;
              final active = _filterRole == role;
              return Padding(padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filterRole = active ? null : role),
                  child: AnimatedContainer(duration: 150.ms,
                    width: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accentBlue.withOpacity(0.12) : AppColors.bgCard,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: active ? AppColors.accentBlue : AppColors.glassBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${role.icon} ${role.label}', style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$count staff', style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          )),
          const SizedBox(height: AppSpacing.md),
          // Search
          TextField(
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Search personnel...',
              prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: AppSpacing.md),
          // Staff list
          ...staff.asMap().entries.map((e) => _PersonnelTile(
            person: e.value, index: e.key, pp: pp)),
        ]);
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: AppRadius.sm),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 8),
      Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
      Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
    ])).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _PersonnelTile extends StatelessWidget {
  const _PersonnelTile({required this.person, required this.index, required this.pp});
  final Personnel person;
  final int index;
  final PersonnelProvider pp;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (person.status) {
      PersonnelStatus.available => AppColors.crisisGreen,
      PersonnelStatus.deployed  => AppColors.crisisAmber,
      PersonnelStatus.offDuty   => AppColors.textMuted,
      PersonnelStatus.emergency => AppColors.crisisRed,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Avatar
          CircleAvatar(radius: 20,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Text(person.avatarInitials,
                style: AppTextStyles.labelLarge.copyWith(color: statusColor))),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(person.name, style: AppTextStyles.titleMedium.copyWith(fontSize: 14)),
              const SizedBox(width: 8),
              StatusBadge(person.status.label, color: statusColor),
            ]),
            const SizedBox(height: 2),
            Text('${person.role.icon} ${person.role.label}  •  ${person.currentLocation ?? "Off-site"}',
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
          ])),
          // Actions
          if (person.status == PersonnelStatus.available)
            _SmallBtn('Deploy', AppColors.crisisAmber,
                () => pp.updateStatus(person.id, PersonnelStatus.deployed)),
          if (person.status == PersonnelStatus.deployed)
            _SmallBtn('Release', AppColors.crisisGreen,
                () => pp.updateStatus(person.id, PersonnelStatus.available)),
        ]),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * index)).slideX(begin: -0.03);
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        textStyle: AppTextStyles.labelSmall.copyWith(fontSize: 11)),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
