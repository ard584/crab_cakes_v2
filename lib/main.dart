import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/project_selection.dart';

// importing startup provider(s)
import 'package:crab_cakes/infrastructure/providers/startup_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //startup routines
    final startup = ref.watch(startupProvider);

    //here we ensure that the startup routines execute successfully before opening the app
    return startup.when(
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(home: Text("Startup error: $e")),
      data: (_) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          useMaterial3: true,

          // Use our presentation's dark blue for accents
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF08345A),
            brightness: Brightness.light,
          ),

          // Light blue background
          scaffoldBackgroundColor: const Color(0xFFEAF4FB),

          // Light blue top bars with dark blue text
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD6EAF5),
            foregroundColor: Color(0xFF08345A),
          ),
        ),
        home: ProjectSelection(),
      ),
    );
  }
}
