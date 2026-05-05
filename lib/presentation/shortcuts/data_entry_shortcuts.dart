import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crab_cakes/presentation/intents/save_intent.dart';
import 'package:crab_cakes/presentation/screens/check_database_screen.dart';

class DataEntryShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onSave;
  final Function(int)? onTableSwitch;

  const DataEntryShortcuts({
    super.key,
    required this.child,
    required this.onSave,
    this.onTableSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.f12): const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.f1): const TableSwitchIntent(0),
        LogicalKeySet(LogicalKeyboardKey.f2): const TableSwitchIntent(1),
        LogicalKeySet(LogicalKeyboardKey.f3): const TableSwitchIntent(2),
        LogicalKeySet(LogicalKeyboardKey.f4): const TableSwitchIntent(3),
        LogicalKeySet(LogicalKeyboardKey.f5): const CheckDatabaseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (_) {
              onSave();
              return null;
            },
          ),
          TableSwitchIntent: CallbackAction<TableSwitchIntent>(
            onInvoke: (intent) {
              onTableSwitch?.call(intent.index);
              return null;
            },
          ),
          CheckDatabaseIntent: CallbackAction<CheckDatabaseIntent>(
            onInvoke: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CheckDatabaseScreen(),
                ),
              );
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
