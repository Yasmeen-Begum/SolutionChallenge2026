import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/crisis_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/sos/sos_screen.dart';
import '../../features/timeline/timeline_screen.dart';
import '../../features/floor_map/floor_map_screen.dart';
import '../../features/comms/comms_screen.dart';
import '../../features/personnel/personnel_screen.dart';
import '../../features/ai_assist/ai_assist_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded,         label: 'Command'),
    _NavItem(icon: Icons.sos_rounded,               label: 'SOS'),
    _NavItem(icon: Icons.timeline_rounded,          label: 'Timeline'),
    _NavItem(icon: Icons.map_rounded,               label: 'Floor Map'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Comms'),
    _NavItem(icon: Icons.people_rounded,            label: 'Personnel'),
    _NavItem(icon: Icons.auto_awesome_rounded,      label: 'AI Assist'),
  ];

  static const _screens = [
    DashboardScreen(),
    SosScreen(),
    TimelineScreen(),
    FloorMapScreen(),
    CommsScreen(),
    PersonnelScreen(),
    AiAssistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Row(
        children: [
          if (isWide) _buildRail(),
          Expanded(
            child: Column(
              children: [
                _CrisisBanner(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: 250.ms,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildRail() {
    return Consumer<CrisisProvider>(
      builder: (_, cp, __) {
        final isCritical = cp.threatLevel == ThreatLevel.critical;
        return Container(
          width: 80,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(
              right: BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Logo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isCritical
                        ? [AppColors.crisisRed, const Color(0xFF7F1D1D)]
                        : [AppColors.accentBlue, AppColors.accentIndigo],
                  ),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
              ).animate(onPlay: (c) => isCritical ? c.repeat() : c.stop())
                .shimmer(duration: 1000.ms, color: Colors.white24),
              const SizedBox(height: 4),
              Text('CS', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _navItems.length,
                  itemBuilder: (_, i) => _RailItem(
                    item: _navItems[i],
                    isSelected: _selectedIndex == i,
                    onTap: () => setState(() => _selectedIndex = i),
                    showBadge: i == 1 && cp.active.isNotEmpty,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: _navItems
            .map((n) => BottomNavigationBarItem(icon: Icon(n.icon, size: 20), label: n.label))
            .toList(),
      ),
    );
  }
}

// ── Sidebar nav item ────────────────────────────────────────────────────────
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentBlue.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.accentBlue.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
                    ),
                    if (showBadge)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.crisisRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Crisis banner ────────────────────────────────────────────────────────────
class _CrisisBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CrisisProvider>(
      builder: (_, cp, __) {
        final level = cp.threatLevel;
        if (level == ThreatLevel.normal) return const SizedBox.shrink();

        final isCritical = level == ThreatLevel.critical;
        final color = isCritical ? AppColors.crisisRed : AppColors.crisisAmber;
        final label = isCritical ? '⚠️  CRITICAL THREAT LEVEL — Active emergencies on site'
                                 : '🔶  ELEVATED THREAT LEVEL — Incidents under management';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: color.withOpacity(0.15),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ).animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.7,0.7), end: const Offset(1.3,1.3), duration: 800.ms)
                .then().scale(begin: const Offset(1.3,1.3), end: const Offset(0.7,0.7), duration: 800.ms),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ),
              Text(
                '${cp.active.length} Active',
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
