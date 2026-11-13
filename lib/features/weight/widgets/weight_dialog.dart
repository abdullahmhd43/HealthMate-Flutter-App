import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/validators.dart';
import '../models/weight_entry.dart';

/// Asks for a date and weight. Returns the entry, or null if cancelled.
Future<WeightEntry?> showWeightDialog(BuildContext context,
    {double? initialKg}) {
  return showDialog<WeightEntry>(
    context: context,
    builder: (_) => _WeightDialog(initialKg: initialKg),
  );
}

class _WeightDialog extends StatefulWidget {
  const _WeightDialog({this.initialKg});

  final double? initialKg;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight = TextEditingController(
    text: widget.initialKg == null ? '' : widget.initialKg!.toStringAsFixed(1),
  );
  DateTime _date = DateHelper.dateOnly(DateTime.now());

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: AppConstants.earliestDate,
      lastDate: DateHelper.dateOnly(now),
    );
    if (picked != null) setState(() => _date = DateHelper.dateOnly(picked));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(WeightEntry(
      date: DateHelper.toIso(_date),
      weightKg: Validators.parseDecimal(_weight.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log weight'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(DateHelper.display(_date)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('weight_field'),
              controller: _weight,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
              ),
              validator: Validators.weight,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
