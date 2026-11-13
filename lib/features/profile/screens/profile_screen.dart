import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/models/user_goals.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

/// Edit body details; shows BMI and offers goals that fit the profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    _name = TextEditingController(text: p.name);
    _age = TextEditingController(text: p.age?.toString() ?? '');
    _height = TextEditingController(text: _fmt(p.heightCm));
    _weight = TextEditingController(text: _fmt(p.weightKg));
    _gender = p.gender;
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profiles = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await profiles.save(UserProfile(
      name: _name.text.trim(),
      age: int.parse(_age.text.trim()),
      gender: _gender,
      heightCm: Validators.parseDecimal(_height.text),
      weightKg: Validators.parseDecimal(_weight.text),
    ));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  Future<void> _applyGoals(UserProfile profile) async {
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await settings.updateGoals(UserGoals(
      steps: profile.recommendedSteps,
      water: profile.recommendedWater,
      calories: profile.recommendedCalories,
    ));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
        const SnackBar(content: Text('Daily goals updated for your profile')));
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final goals = context.watch<SettingsProvider>().goals;
    final theme = Theme.of(context);
    final decimalFormatter =
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (profile.isComplete) ...[
            _BmiCard(profile: profile),
            const SizedBox(height: 16),
            _GoalSuggestionCard(
              profile: profile,
              currentGoals: goals,
              onApply: () => _applyGoals(profile),
            ),
            const SizedBox(height: 24),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Add your details to see your BMI and get daily goals that fit you. '
                'This stays on your phone.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('profile_name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('profile_age'),
                  controller: _age,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Age (years)',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: Validators.age,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<Gender>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      for (final g in Gender.values)
                        ButtonSegment(value: g, label: Text(g.label)),
                    ],
                    selected: {if (_gender != null) _gender!},
                    onSelectionChanged: (s) =>
                        setState(() => _gender = s.isEmpty ? null : s.first),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('profile_height'),
                  controller: _height,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [decimalFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height_rounded),
                  ),
                  validator: Validators.height,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('profile_weight'),
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [decimalFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: Validators.weight,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('profile_save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi = profile.bmi!;
    final category = profile.bmiCategory!;
    // Position of the marker on a 15..40 BMI scale.
    final position = ((bmi - 15) / 25).clamp(0.0, 1.0).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Body mass index',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bmi.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(category.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: category.color, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 8,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          // 15-18.5, 18.5-25, 25-30, 30-40 on a 25-wide scale.
                          for (final band in const [
                            (3.5, Color(0xFF1E88E5)),
                            (6.5, Color(0xFF43A047)),
                            (5.0, Color(0xFFF59E0B)),
                            (10.0, Color(0xFFE53935)),
                          ])
                            Expanded(
                              flex: (band.$1 * 10).round(),
                              child: ColoredBox(color: band.$2),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width * position - 6).clamp(0.0, width - 12).toDouble(),
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 22,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                            color: theme.colorScheme.onSurface, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            'BMI is a general guide only. It does not replace advice from a health professional.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GoalSuggestionCard extends StatelessWidget {
  const _GoalSuggestionCard({
    required this.profile,
    required this.currentGoals,
    required this.onApply,
  });

  final UserProfile profile;
  final UserGoals currentGoals;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = currentGoals.steps == profile.recommendedSteps &&
        currentGoals.water == profile.recommendedWater &&
        currentGoals.calories == profile.recommendedCalories;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recommended daily goals',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          row('Steps', Formatters.steps(profile.recommendedSteps)),
          row('Water', Formatters.water(profile.recommendedWater)),
          row('Calories from steps',
              Formatters.calories(profile.recommendedCalories)),
          const SizedBox(height: 10),
          if (matches)
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Text('Your goals already match',
                    style: theme.textTheme.bodySmall),
              ],
            )
          else
            OutlinedButton(
              key: const Key('apply_goals'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
              onPressed: onApply,
              child: const Text('Use these goals'),
            ),
        ],
      ),
    );
  }
}
