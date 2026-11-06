import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_helper.dart';
import '../models/health_record.dart';
import '../providers/health_records_provider.dart';

/// Asks for confirmation, deletes [record] from SQLite and shows feedback.
/// Returns true when the record was actually deleted.
Future<bool> confirmAndDeleteRecord(
  BuildContext context,
  HealthRecord record,
) async {
  final id = record.id;
  if (id == null) return false;

  final provider = context.read<HealthRecordsProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_outline_rounded,
          color: Theme.of(dialogContext).colorScheme.error, size: 32),
      title: const Text('Delete this record?'),
      content: Text(
        'The record for ${DateHelper.display(record.dateTime)} will be '
        'permanently removed. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  final error = await provider.deleteRecord(id);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(error ?? 'Record deleted')),
  );
  return error == null;
}
