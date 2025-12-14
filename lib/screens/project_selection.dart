import 'package:flutter/material.dart';

class ProjectSelection extends StatelessWidget {
  const ProjectSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Project')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(40.0),
          child: Column(
            spacing: 16.0,
            children: <Widget>[
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.file_open),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Colorado River', textScaler: TextScaler.linear(1.3),),
                        Text('Electrofishing', textScaler: TextScaler.linear(1.0), style: TextStyle(color: Colors.blueGrey),),
                        Text('11/24/2025', textScaler: TextScaler.linear(1.0), style: TextStyle(color: Colors.blueGrey),)
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
              ),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.file_open),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Colorado River', textScaler: TextScaler.linear(1.3),),
                        Text('Hoop Fishing', textScaler: TextScaler.linear(1.0), style: TextStyle(color: Colors.blueGrey),),
                        Text('09/08/2025', textScaler: TextScaler.linear(1.0), style: TextStyle(color: Colors.blueGrey),)
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
              ),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.file_open),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Colorado River', textScaler: TextScaler.linear(1.3),),
                        Text('Electrofishing', textScaler: TextScaler.linear(1.0), style: TextStyle(color: Colors.blueGrey),),
                        Text('03/11/2025', textScaler: TextScaler.linear(1.0), style: TextStyle(color: Colors.blueGrey),)
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
