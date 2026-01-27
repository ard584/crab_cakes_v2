import 'package:logger/logger.dart';

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,      // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 80,      // Width of the output
    colors: true,        // Colorful log messages
    printEmojis: true,   // Print an emoji for each log message
  ),
);