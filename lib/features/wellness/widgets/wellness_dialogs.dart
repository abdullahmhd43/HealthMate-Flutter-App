import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/validators.dart';
import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';
import '../models/workout_entry.dart';

/// Date button used by every wellness dialog.
class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: AppConstants.earliestDate,
          lastDate: DateHelper.dateOnly(DateTime.now()),
        );
        if (picked != null) onChanged(DateHelper.dateOnly(picked));
      },
      icon: const Icon(Icons.calendar_month_rounded),
      label: Text(DateHelper.display(date)),
    );
  }
}

List<Widget> _dialogActions(BuildContext context, VoidCallback onSave) => [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
        onPressed: onSave,
        child: const Text('Save'),
      ),
    ];

// ------------------------------------------------------------------ sleep
Future<SleepEntry?> showSleepDialog(BuildContext context,
    {SleepEntry? initial}) {
  return showDialog<SleepEntry>(
    context: context,
    builder: (_) => _SleepDialog(initial: initial),
  );
}

class _SleepDialog extends StatefulWidget {
  const _SleepDialog({this.initial});

  final SleepEntry? initial;

  @override
  State<_SleepDialog> createState() => _SleepDialogState();
}

class _SleepDialogState extends State<_SleepDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hours = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.hours.toStringAsFixed(1),
  );
  late DateTime _date = widget.initial?.dateTime ??
      DateHelper.dateOnly(DateTime.now());
  late int _quality = widget.initial?.quality ?? 4;

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(SleepEntry(
      date: DateHelper.toIso(_date),
      hours: Validators.parseDecimal(_hours.text),
      quality: _quality,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log sleep'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateButton(
                  date: _date, onChanged: (d) => setState(() => _date = d)),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('sleep_hours_field'),
                controller: _hours,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Hours slept',
                  suffixText: 'h',
                ),
                validator: (v) => Validators.decimalInRange(v,
                    label: 'Sleep', min: 1, max: 24, unit: ' hours'),
              ),
              const SizedBox(height: 16),
              const Text('Sleep quality'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var q = 1; q <= 5; q++)
                    ChoiceChip(
                      label: Text(SleepEntry.labelFor(q)),
                      selected: _quality == q,
                      onSelected: (_) => setState(() => _quality = q),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }
}

// ---------------------------------------------------------------- workout
Future<WorkoutEntry?> showWorkoutDialog(BuildContext context) {
  return showDialog<WorkoutEntry>(
    context: context,
    builder: (_) => const _WorkoutDialog(),
  );
}

class _WorkoutDialog extends StatefulWidget {
  const _WorkoutDialog();

  @override
  State<_WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<_WorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _minutes = TextEditingController();
  final _calories = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateHelper.dateOnly(DateTime.now());
  String _type = WorkoutTypes.all.first.name;

  @override
  void dispose() {
    _minutes.dispose();
    _calories.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _minutesValidator(String? value) {
    final base = Validators.wholeNumber(value, label: 'Duration', max: 600);
    if (base != null) return base;
    if (int.parse(value!.trim()) == 0) return 'Duration must be greater than 0';
    return null;
  }

  String? _caloriesValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    return Validators.wholeNumber(value, label: 'Calories', max: 5000);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final caloriesText = _calories.text.trim();
    Navigator.of(context).pop(WorkoutEntry(
      date: DateHelper.toIso(_date),
      type: _type,
      minutes: int.parse(_minutes.text.trim()),
      calories: caloriesText.isEmpty ? 0 : int.parse(caloriesText),
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log workout'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateButton(
                  date: _date, onChanged: (d) => setState(() => _date = d)),
              const SizedBox(height: 16),
              const Text('Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in WorkoutTypes.all)
                    ChoiceChip(
                      avatar: Icon(type.icon, size: 18),
                      label: Text(type.name),
                      selected: _type == type.name,
                      onSelected: (_) => setState(() => _type = type.name),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('workout_minutes_field'),
                controller: _minutes,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  suffixText: 'min',
                ),
                validator: _minutesValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('workout_calories_field'),
                controller: _calories,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Calories burned (optional)',
                  suffixText: 'kcal',
                ),
                validator: _caloriesValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }
}

// ------------------------------------------------------------------- mood
Future<MoodEntry?> showMoodDialog(BuildContext context,
    {MoodEntry? initial}) {
  return showDialog<MoodEntry>(
    context: context,
    builder: (_) => _MoodDialog(initial: initial),
  );
}

class _MoodDialog extends StatefulWidget {
  const _MoodDialog({this.initial});

  final MoodEntry? initial;

  @override
  State<_MoodDialog> createState() => _MoodDialogState();
}

class _MoodDialogState extends State<_MoodDialog> {
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  late DateTime _date = widget.initial?.dateTime ??
      DateHelper.dateOnly(DateTime.now());
  late int _mood = widget.initial?.mood ?? 4;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(MoodEntry(
      date: DateHelper.toIso(_date),
      mood: _mood,
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How do you feel?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateButton(
                date: _date, onChanged: (d) => setState(() => _date = d)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var m = 1; m <= 5; m++)
                  ChoiceChip(
                    key: Key('mood_$m'),
                    label: Text('${MoodScale.emoji(m)} ${MoodScale.label(m)}'),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }
}
