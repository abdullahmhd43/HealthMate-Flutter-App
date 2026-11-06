import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/validators.dart';

/// Asks for a new goal value. Returns the validated number, or null if the
/// dialog was cancelled.
Future<int?> showGoalDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String unit,
  required int current,
  required int max,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _GoalDialog(
      title: title,
      label: label,
      unit: unit,
      current: current,
      max: max,
    ),
  );
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({
    required this.title,
    required this.label,
    required this.unit,
    required this.current,
    required this.max,
  });

  final String title;
  final String label;
  final String unit;
  final int current;
  final int max;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(int.parse(_controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('goal_field'),
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\-.,]')),
          ],
          decoration: InputDecoration(
            labelText: widget.label,
            suffixText: widget.unit,
          ),
          validator: (v) =>
              Validators.goal(v, label: widget.label, max: widget.max),
          onFieldSubmitted: (_) => _submit(),
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
