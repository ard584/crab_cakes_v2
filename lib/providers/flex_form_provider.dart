import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:ui_prototype/services/projects/flex_project_provider.dart';

final flexTableControllersProvider = Provider.autoDispose
    .family<Map<String, TextEditingController>, String>((ref, tableName) {
      final flexProject = ref.watch(currentFlexProjectProvider).value;

      if (flexProject == null)
        throw Exception("flexProject is null [flexTableControllersProvider]");

      final table = flexProject.tables[tableName];

      if (table == null)
        throw Exception(
          "table $tableName is null [flexTableControllersProvider]",
        );
      final attributes = table.attributes;

      final Map<String, TextEditingController> controllers = {};

      for (final attribute in attributes) {
        controllers[attribute.name] = TextEditingController(
          text: attribute.defaultValue?.toString() ?? '',
        );
      }
      ;

      ref.onDispose(() {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      });

      return controllers;
    });

//TODO: Implement form controller provider
