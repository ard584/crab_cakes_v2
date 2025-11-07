import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ SOLUTION: Always start a new screen with a Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // The back button is automatically provided by the Scaffold/Navigator
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            spacing: 16.0,
            children: <Widget>[
              ReusableLeftAlignedText(text: 'USB Backup Locations'),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.usb),
                    const SizedBox(width: 8),
                    Text('USB Drive 1'),
                    Spacer(),
                    IconButton(
                      tooltip: 'Eject USB Drive from backup pool.',
                      onPressed: () {
                        print('Tapped settings');
                      },
                      icon: const Icon(Icons.eject),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.usb),
                    const SizedBox(width: 8),
                    Text('USB Drive 1'),
                    Spacer(),
                    IconButton(
                      tooltip: 'Eject USB Drive from backup pool.',
                      onPressed: () {
                        print('Tapped settings');
                      },
                      icon: const Icon(Icons.eject),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.usb),
                    const SizedBox(width: 8),
                    Text('USB Drive 1'),
                    Spacer(),
                    IconButton(
                      tooltip: 'Eject USB Drive from backup pool.',
                      onPressed: () {
                        print('Tapped settings');
                      },
                      icon: const Icon(Icons.eject),
                    ),
                  ],
                ),
              ),
              FloatingActionButton.extended(
                tooltip: 'Add USB Drive to the backup pool.',
                icon: Icon(Icons.add),
                onPressed: () {
                  print('Button pressed');
                },
                label: const Text('Add USB Drive'),
              ),
              divider,
              ReusableLeftAlignedText(text: 'Paired PIT Readers'),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.bluetooth_connected),
                    const SizedBox(width: 8),
                    Text('Biomark HPR Lite'),
                    Spacer(),
                    IconButton(
                      tooltip: 'Disconnect \'Biomark HPR Lite\'.',
                      onPressed: () {
                        print('Tapped settings');
                      },
                      icon: const Icon(Icons.bluetooth_disabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final divider = Divider(height: 1.0, color: Colors.grey);

final reusableBoxDecoration = BoxDecoration(
  color: Colors.grey.shade100, // Light background color
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

final reusablePadding = EdgeInsets.all(16);

class ReusableLeftAlignedText extends StatelessWidget {
  final String text;

  const ReusableLeftAlignedText({super.key, required this.text});

  @override
  Widget build(BuildContext build) {
    return (Align(alignment: Alignment.centerLeft, child: Text(text)));
  }
}
