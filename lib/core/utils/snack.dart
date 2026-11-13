import 'package:flutter/material.dart';

/// Replaces any visible snack bar with a new one showing [message].
void showSnack(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
