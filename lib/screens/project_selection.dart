import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/providers/db_provider.dart';
import 'package:ui_prototype/screens/data_entry_screen.dart';
import 'package:ui_prototype/screens/project_creation.dart';
import 'package:ui_prototype/services/projects/project_service.dart';
import '../components/project_widget.dart';

class _ProjectSelectionState extends ConsumerState<ProjectSelection> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(projectsRepositoryProvider);

    if (repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Project')),
      body: FutureBuilder(
        future: repo.getAllProjects(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return Center(child: Text('No projects found'));
          }

          return Padding(
            padding: EdgeInsets.all(40.0),
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectWidget(
                  contextMenu: ContextMenu(entries: entries),
                  projectTitle: project.title,
                  projectDescription: project.description,
                  projectUpdatedAt: project.updatedAt,
                  onPressed: () async {
                    await ref
                        .read(projectServiceProvider)
                        .openProject(project.dbPath);

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

final entries = <ContextMenuEntry>[
  const MenuHeader(text: "Project Settings"),
  MenuItem(
    label: Text("Delete"),
    icon: Icon(Icons.delete),
    value: 'delete',
    onSelected: (value) {
      print("DELETE CALLED ON VALUE $value");
    },
  ),
];

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
