import 'package:flutter/material.dart';
import 'package:ui_prototype/models/project.dart';
import 'package:ui_prototype/screens/project_creation.dart';
import '../components/project_widget.dart';
import 'package:ui_prototype/services/load_project.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';
import 'package:ui_prototype/dialogs/project_error_dialog.dart';



class _ProjectSelectionState extends State<ProjectSelection> {
  Future<void> openProject(String dbPath) async {
    if (!isValidDbPath(dbPath)) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Invalid Database Path'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Database path must end in .db and contain no spaces or illegal characters.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Invalid path: \'$dbPath\'',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );

      return;
    }

    try {
      // Try to read the project schema
      final projectDb = await readProjectSchema(dbPath);
      debugPrint(projectDb.toString());
    } on ProjectDbException catch (e) {
      if (!mounted) return;
      await showProjectDbErrorDialog(context, e);
    } catch (e, st) {
      debugPrint('Unexpected error: $e\n$st');

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Unexpected Error'),
          content: Text('Something went wrong while opening the project.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Project')),
      body: Padding(
        padding: EdgeInsets.all(40.0),
        child: ListView.builder(
          itemCount: widget.projectsList.length,
          itemBuilder: (context, index) {
            return ProjectWidget(
              projectTitle: widget.projectsList[index].title,
              projectDescription: widget.projectsList[index].description,
              projectUpdatedAt: widget.projectsList[index].updatedAt,
              onPressed: () => openProject(widget.projectsList[index].dbPath),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProjectCreationScreen(),
            ),
          );
        },
        tooltip: 'Create a new project',
        label: Text('Create Project'),
        icon: Icon(Icons.add),
      ),
    );
  }
}

class ProjectSelection extends StatefulWidget {
  final List<ProjectModel> projectsList;

  const ProjectSelection({super.key, required this.projectsList});

  @override
  State<ProjectSelection> createState() => _ProjectSelectionState();
}

final reusableBoxDecoration = BoxDecoration(
  color: Colors.grey.shade100, // Light background color
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

final reusablePadding = EdgeInsets.all(16);
