import 'package:flutter/material.dart';

class AsyncNavigator {
  const AsyncNavigator();

  Future<void> asyncRoute(BuildContext context, String route) async {
    Navigator.of(context).pushNamed(route);
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) Navigator.of(context).pop();
  }
}
