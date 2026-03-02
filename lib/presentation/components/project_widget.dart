import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

class ProjectWidget extends StatelessWidget {
  final String projectTitle;
  final String? projectDescription;
  final DateTime projectUpdatedAt;
  final VoidCallback? onPressed;
  final ContextMenu? contextMenu;

  const ProjectWidget({
    super.key,
    required this.projectTitle,
    this.projectDescription,
    required this.projectUpdatedAt,
    this.contextMenu,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;


    Widget child = Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest, // Light background color
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: colorScheme.inversePrimary),
      ),
      padding: reusablePadding,
      child: Row(
        children: <Widget>[
          Icon(Icons.file_open),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(projectTitle, textScaler: TextScaler.linear(1.3)),
              Text(
                projectDescription ?? '',
                textScaler: TextScaler.linear(1.0),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                projectUpdatedAt.toString(),
                textScaler: TextScaler.linear(1.0),
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );

    if (contextMenu == null) return child;

    return ContextMenuRegion(contextMenu: contextMenu!, child: child);
  }
}

final reusablePadding = EdgeInsets.all(16);
