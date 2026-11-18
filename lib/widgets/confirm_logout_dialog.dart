import 'package:flutter/material.dart';

Future<bool> confirmLogout(
  BuildContext context, {
  String actionLabel = 'Log out',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(actionLabel),
          content: Text('Are you sure you want to $actionLabel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;
}
