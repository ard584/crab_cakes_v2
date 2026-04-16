import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/project_selection.dart';

// importing startup provider(s)
import 'package:ui_prototype/infrastructure/providers/startup_provider.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(

    ProviderScope(child: MyApp())
    
    );
}

class MyApp extends ConsumerWidget {

  const MyApp({
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    //startup routines
    final startup = ref.watch(startupProvider);

    //here we ensure that the startup routines execute successfully before opening the app
    return startup.when(
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (e, _) => MaterialApp(home: Text("Startup error: $e")),
      data: (_) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light,),
        ),
        home: ProjectSelection(),
      ),
    );
  }
}