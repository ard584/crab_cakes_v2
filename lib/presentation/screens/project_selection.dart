import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/domain/models/project.dart';
import 'package:crab_cakes/infrastructure/providers/app_db_provider.dart';
import 'package:crab_cakes/presentation/dialogs/confirm_delete.dart';
import 'package:crab_cakes/presentation/screens/data_entry_screen.dart';
import 'package:crab_cakes/presentation/screens/project_creation.dart';
import 'package:crab_cakes/presentation/screens/update_project_screen.dart';
import '../components/project_widget.dart';

class _ProjectSelectionState extends ConsumerState<ProjectSelection> {
  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select a Project')),
      body: projectsAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (projects) {
          return Padding(
            padding: EdgeInsets.all(40.0),
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectWidget(
                  contextMenu: ContextMenu(
                    entries: _buildProjectContextMenu(
                      project: project,
                      ref: ref,
                      context: context,
                    ),
                  ),
                  projectTitle: project.title,
                  projectDescription: project.description,
                  projectUpdatedAt: project.updatedAt,
                  onPressed: () async {
                    await ref
                        .read(projectListProvider.notifier)
                        .selectProject(project: project);

                    // If mounted
                    if (context.mounted) {
                      // Open data entry screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataEntryScreen(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProjectCreationScreen()),
          );
        },
        tooltip: 'Create a new project',
        label: Text('Create Project'),
        icon: Icon(Icons.add),
      ),
    );
  }
}

List<ContextMenuEntry> _buildProjectContextMenu({
  required BuildContext context,
  required ProjectModel project,
  required WidgetRef ref,
}) {
  return [
    MenuHeader(text: "Project Settings"),
    MenuItem(
      label: Text("Delete"),
      icon: Icon(Icons.delete),
      value: 'delete',
      onSelected: (value) async {
        final result = await confirmDelete(
          context,
          "Are you sure you want to delete this project?",
        );

        if (result == true) {
          ref
              .read(projectListProvider.notifier)
              .deleteProject(projectId: project.id);
        }
      },
    ),
    MenuItem(
      label: Text("Edit"),
      icon: Icon(Icons.mode_edit),
      value: 'edit',
      onSelected: (value) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateProjectScreen(project: project),
          ),
        );
      },
    ),
  ];
}

class ProjectSelection extends ConsumerStatefulWidget {
  const ProjectSelection({super.key});

  @override
  ConsumerState<ProjectSelection> createState() => _ProjectSelectionState();
}

final reusableBoxDecoration = BoxDecoration(
  color: Colors.grey.shade100, // Light background color
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

final reusablePadding = EdgeInsets.all(16);
