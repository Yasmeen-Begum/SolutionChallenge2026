import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/incident.dart';
import '../../core/providers/crisis_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/severity_badge.dart';

class FloorMapScreen extends StatefulWidget {
  const FloorMapScreen({super.key});
  @override
  State<FloorMapScreen> createState() => _FloorMapScreenState();
}

class _FloorMapScreenState extends State<FloorMapScreen> {
  int _floor = 0;
  String? _selRoom;

  static const _floorLabels = ['Ground Floor', 'Floor 1', 'Floor 2', 'Floor 3-4'];
  static const _floorSubs = ['Lobby, Restaurant, Kitchen', 'Rooms 101-112', 'Rooms 201-212', 'Rooms 301-412'];

  static final _rooms = <int, List<_R>>{
    0: [_R('lobby','Lobby',0,0,2,2), _R('rest','Restaurant',2,0,2,2), _R('kitchen','Kitchen',4,0,2,1),
        _R('conf_a','Conf A',4,1,1,1), _R('conf_b','Conf B',5,1,1,1),
        _R('gym','Gym',0,2,2,1), _R('pool','Pool',2,2,2,1), _R('spa','Spa',4,2,2,1)],
    1: [for (var i = 1; i <= 12; i++) _R('${100+i}','Room ${100+i}',(i-1)%6,(i-1)~/6,1,1),
        _R('elev','Elevator',2,2,1,1), _R('stairs','Stairs',4,2,1,1)],
    2: [for (var i = 1; i <= 12; i++) _R('${200+i}','Room ${200+i}',(i-1)%6,(i-1)~/6,1,1)],
    3: [for (var i = 1; i <= 6; i++) _R('${300+i}','Room ${300+i}',(i-1)%6,0,1,1),
        for (var i = 1; i <= 6; i++) _R('${400+i}','Room ${400+i}',(i-1)%6,1,1,1)],
  };

  Color _color(String id, List<Incident> incs) {
    for (final inc in incs) {
      if (inc.status == IncidentStatus.resolved) continue;
      final loc = inc.location.toLowerCase();
      final rm = inc.roomNumber?.toLowerCase() ?? '';
      final rid = id.toLowerCase();
      if (rm == rid || loc.contains(rid)) {
        return AppColors.forSeverity(inc.severity.name);
      }
    }
    return AppColors.crisisGreen;
  }

  bool _hasInc(String id, List<Incident> incs) => incs.any((i) =>
    i.status != IncidentStatus.resolved &&
    (i.roomNumber?.toLowerCase() == id.toLowerCase() ||
     i.location.toLowerCase().contains(id.toLowerCase())));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer<CrisisProvider>(builder: (_, cp, __) {
        final rooms = _rooms[_floor] ?? [];
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Interactive Floor Map', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text('Real-time venue layout with incident overlays', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            // Floor tabs
            SizedBox(height: 44, child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: 4,
              itemBuilder: (_, i) {
                final active = i == _floor;
                return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(
                  onTap: () => setState(() { _floor = i; _selRoom = null; }),
                  borderRadius: AppRadius.md,
                  child: AnimatedContainer(duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accentBlue.withOpacity(0.15) : AppColors.bgCard,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: active ? AppColors.accentBlue : AppColors.glassBorder)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_floorLabels[i], style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 12, color: active ? AppColors.accentBlue : AppColors.textSecondary)),
                      Text(_floorSubs[i], style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
                    ]),
                  ),
                ));
              },
            )),
            const SizedBox(height: AppSpacing.md),
            // Grid
            Expanded(child: GlassCard(padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(builder: (_, box) {
                const cols = 6, rows = 3;
                final cw = (box.maxWidth - 30) / cols;
                final ch = (box.maxHeight - 12) / rows;
                return Stack(children: rooms.asMap().entries.map((e) {
                  final r = e.value;
                  final c = _color(r.id, cp.incidents);
                  final sel = r.id == _selRoom;
                  final hi = _hasInc(r.id, cp.incidents);
                  return Positioned(
                    left: r.col * (cw + 6), top: r.row * (ch + 6),
                    width: r.cs * cw + (r.cs - 1) * 6, height: r.rs * ch + (r.rs - 1) * 6,
                    child: GestureDetector(onTap: () => setState(() => _selRoom = r.id),
                      child: AnimatedContainer(duration: 200.ms, decoration: BoxDecoration(
                        color: c.withOpacity(sel ? 0.3 : 0.12), borderRadius: AppRadius.sm,
                        border: Border.all(color: sel ? AppColors.accentBlue : c.withOpacity(0.5), width: sel ? 2 : 1),
                        boxShadow: hi ? [BoxShadow(color: c.withOpacity(0.3), blurRadius: 10)] : null),
                        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(r.label, style: AppTextStyles.labelLarge.copyWith(fontSize: 11), textAlign: TextAlign.center),
                          if (hi) Padding(padding: const EdgeInsets.only(top: 4),
                            child: PulseIndicator(color: c, size: 5)),
                        ])),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 30 * e.key)),
                  );
                }).toList());
              }),
            )),
            const SizedBox(height: AppSpacing.sm),
            // Legend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final l in [('Safe', AppColors.crisisGreen), ('Warning', AppColors.crisisYellow),
                ('High', AppColors.crisisAmber), ('Critical', AppColors.crisisRed)])
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(
                    color: l.$2.withOpacity(0.25), borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: l.$2.withOpacity(0.6)))),
                  const SizedBox(width: 4),
                  Text(l.$1, style: AppTextStyles.labelSmall),
                ])),
            ]),
          ]),
        );
      }),
    );
  }
}

class _R {
  const _R(this.id, this.label, this.col, this.row, this.cs, this.rs);
  final String id, label;
  final int col, row, cs, rs;
}
