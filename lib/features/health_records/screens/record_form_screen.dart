import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/validators.dart';
import '../models/health_record.dart';
import '../providers/health_records_provider.dart';

/// Add a new record, or edit an existing one when [recordId] is given.
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, this.recordId, this.initialDate});

  /// When non-null the screen loads that record from SQLite and edits it.
  final int? recordId;

  /// Pre-selected date for a new record.
  final DateTime? initialDate;

  bool get isEditing => recordId != null;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _waterController = TextEditingController();

  DateTime? _date;
  String? _dateError;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecord());
    } else {
      _setDate(widget.initialDate ?? DateTime.now());
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    final record =
        await context.read<HealthRecordsProvider>().getRecordById(widget.recordId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (record == null) {
        _loadError = 'This record could not be found. It may have been deleted.';
        return;
      }
      _date = record.dateTime;
      _dateController.text = DateHelper.display(record.dateTime);
      _stepsController.text = '${record.steps}';
      _caloriesController.text = '${record.calories}';
      _waterController.text = '${record.water}';
    });
  }

  void _setDate(DateTime date) {
    _date = DateHelper.dateOnly(date);
    _dateController.text = DateHelper.display(_date!);
    _dateError = null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: AppConstants.earliestDate,
      lastDate: DateHelper.dateOnly(now),
      helpText: 'Select record date',
    );
    if (picked != null) {
      setState(() => _setDate(picked));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final dateProblem = Validators.date(_date);
    setState(() => _dateError = dateProblem);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || dateProblem != null) return;

    final provider = context.read<HealthRecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final record = HealthRecord(
      id: widget.recordId,
      date: DateHelper.toIso(_date!),
      steps: int.parse(_stepsController.text.trim()),
      calories: int.parse(_caloriesController.text.trim()),
      water: int.parse(_waterController.text.trim()),
    );

    setState(() => _saving = true);
    final error = widget.isEditing
        ? await provider.updateRecord(record)
        : await provider.addRecord(record);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      // Duplicate dates are shown against the date field; others as a snackbar.
      if (error.contains('already exists')) {
        setState(() => _dateError = error);
      } else {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(widget.isEditing ? 'Record updated' : 'Record saved'),
    ));
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit record' : 'Add record';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_loadError!, textAlign: TextAlign.center),
        ),
      );
    }

    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            widget.isEditing
                ? 'Update the values for this day.'
                : 'Log your activity for a day. Only one record per date is allowed.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('date_field'),
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: InputDecoration(
              labelText: 'Date',
              prefixIcon: const Icon(Icons.calendar_month_rounded),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
              errorText: _dateError,
            ),
            validator: (_) => Validators.date(_date),
          ),
          const SizedBox(height: 16),
          _NumberField(
            fieldKey: const Key('steps_field'),
            controller: _stepsController,
            label: 'Steps walked',
            icon: Icons.directions_walk_rounded,
            color: AppColors.steps,
            validator: Validators.steps,
          ),
          const SizedBox(height: 16),
          _NumberField(
            fieldKey: const Key('calories_field'),
            controller: _caloriesController,
            label: 'Calories burned (kcal)',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.calories,
            validator: Validators.calories,
          ),
          const SizedBox(height: 16),
          _NumberField(
            fieldKey: const Key('water_field'),
            controller: _waterController,
            label: 'Water intake (ml)',
            icon: Icons.water_drop_rounded,
            color: AppColors.water,
            validator: Validators.water,
            action: TextInputAction.done,
            onSubmitted: _save,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            key: const Key('save_button'),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(widget.isEditing ? 'Save changes' : 'Save record'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('cancel_button'),
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.validator,
    this.action = TextInputAction.next,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final String? Function(String?) validator;
  final TextInputAction action;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      textInputAction: action,
      // Letters are blocked, but '-' and '.' are allowed so that negative or
      // decimal input produces a clear validation message instead of silently
      // being ignored.
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-.,]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
      ),
      validator: validator,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
    );
  }
}
