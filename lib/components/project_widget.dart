import 'package:flutter/material.dart';

class ProjectWidget extends StatelessWidget {
  final String projectTitle;
  final String? projectDescription;
  final DateTime projectUpdatedAt;

  const ProjectWidget({
    super.key,
    required this.projectTitle,
    this.projectDescription,
    required this.projectUpdatedAt
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: reusableBoxDecoration,
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
                style: TextStyle(color: Colors.blueGrey),
              ),
              Text(
                projectUpdatedAt.toString(),
                textScaler: TextScaler.linear(1.0),
                style: TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            onPressed: () {
              print('Tapped settings');
            },
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
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
