import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/services/flex_field/flex_field_factory.dart';
import 'package:ui_prototype/services/projects/flex_project_provider.dart';

class DataEntryScreen extends ConsumerWidget {
  const DataEntryScreen({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentFlexProjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: projectAsync.when(
          data: (project) => Text('Data Entry'),
          error: (_, __) => const Text("Error"),
          loading: () => const Text('Loading...'),
        ),
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return Center(child: Text("No project selected"));
          }

          // Reaqd the current project into a variable
          final projectValue = ref.read(currentFlexProjectProvider).value;

          // Get the name of the first table and open it
          final firstTableName = projectValue?.tables.keys.first;
          final table = projectValue?.tables[firstTableName];

          // Check if table exists
          if (table != null) {

            // Extract attributes
            final attributes = table.attributes;

            // Iterate through attributes
            return ListView.builder(
              itemCount: attributes.length,
              itemBuilder: (context, index) {
                final attr = attributes.toList()[index];

                // Get the correct type of field for current attribute
                return FlexFieldFactory.createField(
                  config: FlexFieldConfig(
                    label: attr.name,
                    dataType: attr.dataType,
                    isRequired: attr.isNotNullable,
                  ),

                  // Placeholder for now, doesn't do anything
                  controller: TextEditingController(),
                );
              },
            );
          }

          // If table is null, tell user
          else {
            return Center(child: Text('Table is null'),);
          }
        },

        // Handle error and loading states
        error: (err, stack) => Center(child: Text("Error: $err")),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// class _MyHomePageState extends State<DataEntryScreen> {
//   // Retained for now, but not actively used in this snippet

//   // This function is the handler passed to onWidgetSelected,
//   // correctly placed as a direct method of the State class.
//   void _handleMenuAction(String selectedValue) {
//     // Use a switch statement to determine the action based on the returned value
//     switch (selectedValue) {
//       case 'switch_project':
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => ProjectSelection()),
//         );
//       case 'export_data':
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const ExportScreen()),
//         );
//       case 'settings':
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const SettingsScreen()),
//         );
//       default:
//         log.w('Unknown action selected: $selectedValue');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       drawer: Drawer(
//         child: Column(
//           children: [
//             SizedBox(
//               height: 80.0,
//               child: const DrawerHeader(child: Center(child: Text('Tables'))),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: ReorderableSidebar(initialItems: sidebarMenuItems),
//               ),
//             ),
//             AppMenuButton(
//               options: myCustomMenu, // The list defined in Step 1
//               onWidgetSelected:
//                   _handleMenuAction, // The handler method defined in Step A
//             ),
//           ],
//         ),
//       ),
//       body: ListView(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     children: <Widget>[
//                       ReusableInputField(
//                         labelText: 'PIT ID',
//                         error: 'Warning: This tag was recently scanned',
//                       ),
//                       ReusableInputField(
//                         labelText: 'Species',
//                         error: 'Expected Value: Goldfish',
//                       ),
//                       ReusableInputField(labelText: 'Total Length'),
//                       ReusableInputField(labelText: 'Fork Length'),
//                       ReusableInputField(labelText: 'Weight'),
//                     ],
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     children: <Widget>[
//                       ReusableInputField(labelText: 'Catch Time'),
//                       ReusableInputField(labelText: 'River Mile'),
//                       ReusableInputField(labelText: 'Notes'),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           Align(
//             alignment: Alignment.centerRight,
//             child: Container(
//               margin: const EdgeInsets.all(20.0),
//               child: FloatingActionButton.extended(
//                 onPressed: null,
//                 label: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Text("Save Record"),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

// final List<ReorderableItem> sidebarMenuItems = [
//   ReorderableItem(
//     widget: ListTile(
//       title: const Text('Trip'),
//       leading: const Icon(Icons.table_chart),
//       onTap: () => {log.d("Trip tapped")},
//     ),
//   ),
//   ReorderableItem(
//     widget: ListTile(
//       title: const Text('Batch'),
//       leading: const Icon(Icons.table_chart),
//       onTap: () => {log.d("Batch tapped")},
//     ),
//   ),
//   ReorderableItem(
//     widget: ListTile(
//       title: const Text('Specimen'),
//       leading: const Icon(Icons.table_chart),
//       onTap: () => {log.d("Specimen tapped")},
//     ),
//   ),
// ];

// // Define this class outside of your main build method
// class ReusableInputField extends StatelessWidget {
//   final String? error;
//   final String labelText;
//   final ValueChanged<String>? onChanged;

//   const ReusableInputField({
//     super.key,
//     this.error,
//     required this.labelText,
//     this.onChanged,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // Your consistent styling (margin, decoration, padding) goes here
//       margin: const EdgeInsets.only(bottom: 16.0),
//       padding: const EdgeInsets.symmetric(horizontal: 12.0),
//       decoration: getBoxDecoration(error, context),
//       child: TextFormField(
//         onChanged: onChanged,
//         decoration: InputDecoration(
//           labelText: labelText,
//           errorText: (error != null) ? '$error' : null,
//           // This removes the default underline/border of the TextField itself
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
//         ),
//       ),
//     );
//   }
// }

// BoxDecoration getBoxDecoration(String? mismatch, BuildContext context) {
//   if (mismatch == null) {
//     return getNormalBoxDecoration(context);
//   }

//   return getErrorBoxDecoration(context);
// }

// BoxDecoration getNormalBoxDecoration(BuildContext context) {
//   return BoxDecoration(
//     color: Colors.grey.shade100, // Light background color
//     borderRadius: BorderRadius.circular(10.0),
//     border: Border.all(color: Colors.grey.shade300),
//   );
// }

// BoxDecoration getErrorBoxDecoration(BuildContext context) {
//   return BoxDecoration(
//     color: Colors.grey.shade100, // Light background color
//     borderRadius: BorderRadius.circular(10.0),
//     border: Border.all(color: Theme.of(context).colorScheme.error),
//   );
// }

// class ReorderableItem {
//   final Widget widget;
//   final Key key;

//   ReorderableItem({required this.widget}) : key = UniqueKey();
// }

// class ReorderableSidebar extends StatefulWidget {
//   final List<ReorderableItem> initialItems;

//   const ReorderableSidebar({super.key, required this.initialItems});

//   @override
//   State<ReorderableSidebar> createState() => _ReorderableSidebarState();
// }

// class _ReorderableSidebarState extends State<ReorderableSidebar> {
//   late List<ReorderableItem> _items;

//   @override
//   void initState() {
//     super.initState();
//     _items = List<ReorderableItem>.from(widget.initialItems);
//   }

//   void _onReorder(int oldIndex, int newIndex) {
//     setState(() {
//       if (newIndex > oldIndex) {
//         newIndex -= 1;
//       }

//       final ReorderableItem item = _items.removeAt(oldIndex);
//       _items.insert(newIndex, item);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ReorderableListView.builder(
//       onReorder: _onReorder,
//       scrollDirection: Axis.vertical,
//       itemCount: _items.length,

//       itemBuilder: (BuildContext context, int index) {
//         final ReorderableItem item = _items[index];

//         return Container(key: item.key, child: item.widget);
//       },
//     );
//   }
// }

// class MenuOption {
//   final Widget childWidget;
//   final String value;
//   const MenuOption({required this.childWidget, required this.value});
// }

// // You would update your AppMenuButton class definition to use MenuOption:
// // final List<MenuOption> options;

// // Define the list of options you want to appear in the pop-up menu
// final List<MenuOption> myCustomMenu = [
//   MenuOption(
//     value:
//         'switch_project', // <--- This String is what gets returned when tapped
//     childWidget: const Row(
//       children: [
//         Icon(Icons.file_open),
//         SizedBox(width: 8),
//         Text('Switch Project'),
//       ],
//     ),
//   ),
//   MenuOption(
//     value: 'export_data', // <--- This String is what gets returned when tapped
//     childWidget: const Row(
//       children: [
//         Icon(Icons.file_download),
//         SizedBox(width: 8),
//         Text('Export Data'),
//       ],
//     ),
//   ),
//   MenuOption(
//     value: 'settings',
//     childWidget: const Row(
//       children: [
//         Icon(Icons.settings),
//         SizedBox(width: 8),
//         Text('Open Settings Menu'),
//       ],
//     ),
//   ),
// ];

// class AppMenuButton extends StatelessWidget {
//   final List<MenuOption> options; // Change from 'widgets' to 'options'
//   final ValueChanged<String> onWidgetSelected;

//   const AppMenuButton({
//     super.key,
//     required this.options, // Accepts objects with Widget + Value
//     required this.onWidgetSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return PopupMenuButton<String>(
//       // Specify the return type
//       onSelected: onWidgetSelected,
//       itemBuilder: (BuildContext context) {
//         return options.map((option) {
//           // CORRECT: Map to PopupMenuItem
//           return PopupMenuItem<String>(
//             value: option.value, // REQUIRED: The value to return on selection
//             child: option.childWidget, // The custom widget you provided
//           );
//         }).toList(); // Return the list of PopupMenuItem objects
//       },
//     );
//   }
// }
