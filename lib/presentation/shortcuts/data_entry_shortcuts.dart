import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_prototype/presentation/intents/save_intent.dart';

class DataEntryShortcuts extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onSave;

  const DataEntryShortcuts({
    super.key,
    required this.child,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // f12 triggers save button
        const SingleActivator(LogicalKeyboardKey.f12): const SaveIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (_) => onSave(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}