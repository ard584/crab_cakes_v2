import 'package:flutter/material.dart';
import 'package:ui_prototype/models/project.dart';
import '../components/project_widget.dart';

class ProjectSelection extends StatelessWidget {
  final List<ProjectModel> projectsList;

  const ProjectSelection({super.key, required this.projectsList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Project')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(40.0),
          child: Column(
            spacing: 16.0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListView.builder(
                itemCount: projectsList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ProjectWidget(
                    projectTitle: projectsList[index].title,
                    projectDescription: projectsList[index].description,
                    projectUpdatedAt: projectsList[index].updatedAt,
                  );
                },
              ),
              FloatingActionButton.extended(
                onPressed: null,
                tooltip: 'Create a new project',
                label: Text('Create Project'),
                icon: Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final reusableBoxDecoration = BoxDecoration(
  color: Colors.grey.shade100, // Light background color
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

final reusablePadding = EdgeInsets.all(16);
