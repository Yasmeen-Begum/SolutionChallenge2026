import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/incident.dart';
import '../../core/providers/crisis_provider.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  IncidentType? _selectedType;
  final _locationCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();
  IncidentSeverity _severity = IncidentSeverity.high;
  bool _submitted = false;
  bool _pressing  = false;

  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _ConfirmationView(onReset: () => setState(() {
      _submitted = false;
      _selectedType = null;
      _locationCtrl.clear();
      _descCtrl.clear();
    }));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency SOS Portal', style: AppTextStyles.headlineLarge),
            Text('Tap a category and press SOS to alert all responders immediately.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            _SOSButton(
              onPressed: _submit,
              pressing: _pressing,
              onLongPressStart: () => setState(() => _pressing = true),
              onLongPressEnd:   () => setState(() => _pressing = false),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Emergency Type', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _TypeGrid(
              selected: _selectedType,
              onSelect: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Severity', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _SeveritySelector(
              selected: _severity,
              onSelect: (s) => setState(() => _severity = s),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _locationCtrl,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Location / Room number (e.g. Room 412, Pool Area)',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descCtrl,
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Brief description of the situation...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crisisRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submit,
                child: Text('🚨  SEND EMERGENCY ALERT',
                    style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an emergency type'),
        backgroundColor: AppColors.crisisAmber,
      ));
      return;
    }

    final incident = Incident(
      id:           _uuid.v4(),
      type:         _selectedType!,
      severity:     _severity,
      status:       IncidentStatus.active,
      title:        '${_selectedType!.label} – ${_locationCtrl.text.trim().isEmpty ? "Location TBD" : _locationCtrl.text.trim()}',
      description:  _descCtrl.text.trim().isEmpty ? 'No description provided.' : _descCtrl.text.trim(),
      location:     _locationCtrl.text.trim().isEmpty ? 'Unknown' : _locationCtrl.text.trim(),
      floor:        0,
      reportedBy:   'Guest / On-site Staff',
      reporterRole: 'SOS Portal',
      reportedAt:   DateTime.now(),
    );

    context.read<CrisisProvider>().addIncident(incident);
    setState(() => _submitted = true);
  }
}

// ── SOS Button ─────────────────────────────────────────────────────────────────
class _SOSButton extends StatelessWidget {
  const _SOSButton({
    required this.onPressed,
    required this.pressing,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final VoidCallback onPressed;
  final bool pressing;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd:   (_) { onLongPressEnd(); onPressed(); },
        child: AnimatedContainer(
          duration: 150.ms,
          width:  pressing ? 140 : 160,
          height: pressing ? 140 : 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.crisisRed,
            boxShadow: [
              BoxShadow(
                color: AppColors.crisisRed.withOpacity(pressing ? 0.6 : 0.35),
                blurRadius: pressing ? 40 : 24,
                spreadRadius: pressing ? 8 : 4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sos_rounded, color: Colors.white, size: 52),
              Text('HELP', style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white, fontSize: 16, letterSpacing: 3)),
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat())
        .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 800.ms)
        .then().scale(begin: const Offset(1.04, 1.04), end: const Offset(1, 1), duration: 800.ms),
    );
  }
}

// ── Type Grid ──────────────────────────────────────────────────────────────────
class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.selected, required this.onSelect});
  final IncidentType? selected;
  final ValueChanged<IncidentType> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: IncidentType.values.map((type) {
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crisisRed.withOpacity(0.2)
                  : AppColors.bgElevated,
              borderRadius: AppRadius.md,
              border: Border.all(
                color: isSelected ? AppColors.crisisRed : AppColors.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  type.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    color: isSelected ? AppColors.crisisRed : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Severity Selector ──────────────────────────────────────────────────────────
class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({required this.selected, required this.onSelect});
  final IncidentSeverity selected;
  final ValueChanged<IncidentSeverity> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: IncidentSeverity.values.map((sev) {
        final isSelected = selected == sev;
        final color = AppColors.forSeverity(sev.name);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(sev),
              child: AnimatedContainer(
                duration: 150.ms,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.18) : AppColors.bgElevated,
                  borderRadius: AppRadius.md,
                  border: Border.all(
                      color: isSelected ? color : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1),
                ),
                child: Column(
                  children: [
                    Text(sev.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(sev.label,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: isSelected ? color : AppColors.textMuted),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Confirmation View ──────────────────────────────────────────────────────────
class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.crisisGreen.withOpacity(0.15),
                  border: Border.all(color: AppColors.crisisGreen.withOpacity(0.4)),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.crisisGreen, size: 56),
              ).animate().scale(begin: const Offset(0.5, 0.5)).fadeIn(),
              const SizedBox(height: 24),
              Text('Help is on the way!',
                  style: AppTextStyles.headlineLarge.copyWith(color: AppColors.crisisGreen)),
              const SizedBox(height: 12),
              Text(
                'Your emergency alert has been sent to all responders.\nEstimated arrival: 2–5 minutes.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Stay calm and remain where you are.',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.glassBorder)),
                child: const Text('Submit Another Alert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
