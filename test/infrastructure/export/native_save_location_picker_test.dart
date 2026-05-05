import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crab_cakes/domain/value_objects/save_file_type.dart';
import 'package:crab_cakes/infrastructure/export/native_save_location_picker.dart';

void main() {
  group('NativeSaveLocationPicker', () {
    late String? capturedSuggestedName;
    late List<XTypeGroup>? capturedAcceptedTypeGroups;
    late FileSaveLocation? fakeLocation;
    late Object? errorToThrow;

    NativeSaveLocationPicker createPicker() {
      return NativeSaveLocationPicker(
        getSaveLocationOverride: ({
          required String suggestedName,
          required List<XTypeGroup> acceptedTypeGroups,
        }) async {
          capturedSuggestedName = suggestedName;
          capturedAcceptedTypeGroups = acceptedTypeGroups;

          final error = errorToThrow;
          if (error != null) {
            throw error;
          }

          return fakeLocation;
        },
      );
    }

    setUp(() {
      capturedSuggestedName = null;
      capturedAcceptedTypeGroups = null;
      fakeLocation = null;
      errorToThrow = null;
    });

    test('returns null when user cancels save dialog', () async {
      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(result, isNull);
    });

    test('returns selected file path when location is selected', () async {
      fakeLocation = FileSaveLocation('/tmp/export.csv');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(result, '/tmp/export.csv');
    });

    test('passes suggestedName to save location selector', () async {
      fakeLocation = FileSaveLocation('/tmp/export.csv');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'my_export.csv',
        type: SaveFileType.csv,
      );

      expect(capturedSuggestedName, 'my_export.csv');
    });

    test('passes one accepted type group', () async {
      fakeLocation = FileSaveLocation('/tmp/export.csv');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(capturedAcceptedTypeGroups, isNotNull);
      expect(capturedAcceptedTypeGroups, hasLength(1));
    });

    test('uses CSV type group for csv file type', () async {
      fakeLocation = FileSaveLocation('/tmp/export.csv');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      final group = capturedAcceptedTypeGroups!.single;

      expect(group.label, 'CSV Files');
      expect(group.extensions, ['csv']);
      expect(group.mimeTypes, ['text/csv']);
    });

    test('uses JSON type group for json file type', () async {
      fakeLocation = FileSaveLocation('/tmp/project.json');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'project.json',
        type: SaveFileType.json,
      );

      final group = capturedAcceptedTypeGroups!.single;

      expect(group.label, 'JSON Files');
      expect(group.extensions, ['json']);
      expect(group.mimeTypes, ['application/json']);
    });

    test('uses text type group for txt file type', () async {
      fakeLocation = FileSaveLocation('/tmp/export.txt');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'export.txt',
        type: SaveFileType.txt,
      );

      final group = capturedAcceptedTypeGroups!.single;

      expect(group.label, 'Text Files');
      expect(group.extensions, ['txt']);
      expect(group.mimeTypes, ['txt']);
    });

    test('does not append csv extension itself', () async {
      fakeLocation = FileSaveLocation('/tmp/export');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'export',
        type: SaveFileType.csv,
      );

      expect(result, '/tmp/export');
    });

    test('does not modify selected csv path', () async {
      fakeLocation = FileSaveLocation('/tmp/custom_name.csv');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'suggested.csv',
        type: SaveFileType.csv,
      );

      expect(result, '/tmp/custom_name.csv');
    });

    test('does not modify selected json path', () async {
      fakeLocation = FileSaveLocation('/tmp/custom_name.json');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'suggested.json',
        type: SaveFileType.json,
      );

      expect(result, '/tmp/custom_name.json');
    });

    test('does not modify selected txt path', () async {
      fakeLocation = FileSaveLocation('/tmp/custom_name.txt');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'suggested.txt',
        type: SaveFileType.txt,
      );

      expect(result, '/tmp/custom_name.txt');
    });

    test('supports suggested name without extension for csv', () async {
      fakeLocation = FileSaveLocation('/tmp/export.csv');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'export',
        type: SaveFileType.csv,
      );

      expect(capturedSuggestedName, 'export');
      expect(capturedAcceptedTypeGroups!.single.extensions, ['csv']);
    });

    test('supports suggested name without extension for json', () async {
      fakeLocation = FileSaveLocation('/tmp/project.json');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'project',
        type: SaveFileType.json,
      );

      expect(capturedSuggestedName, 'project');
      expect(capturedAcceptedTypeGroups!.single.extensions, ['json']);
    });

    test('supports suggested name without extension for txt', () async {
      fakeLocation = FileSaveLocation('/tmp/export.txt');

      final picker = createPicker();

      await picker.getLocation(
        suggestedName: 'export',
        type: SaveFileType.txt,
      );

      expect(capturedSuggestedName, 'export');
      expect(capturedAcceptedTypeGroups!.single.extensions, ['txt']);
    });

    test('supports empty suggested name', () async {
      fakeLocation = FileSaveLocation('/tmp/export.csv');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: '',
        type: SaveFileType.csv,
      );

      expect(result, '/tmp/export.csv');
      expect(capturedSuggestedName, '');
    });

    test('supports suggested name with spaces', () async {
      fakeLocation = FileSaveLocation('/tmp/my export.csv');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'my export.csv',
        type: SaveFileType.csv,
      );

      expect(result, '/tmp/my export.csv');
      expect(capturedSuggestedName, 'my export.csv');
    });

    test('supports Windows style selected path', () async {
      fakeLocation = FileSaveLocation(r'C:\Users\anthony\Desktop\export.csv');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(result, r'C:\Users\anthony\Desktop\export.csv');
    });

    test('supports relative selected path', () async {
      fakeLocation = FileSaveLocation('exports/export.csv');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(result, 'exports/export.csv');
    });

    test('propagates selector exception', () async {
      errorToThrow = StateError('native picker failed');

      final picker = createPicker();

      expect(
        () => picker.getLocation(
          suggestedName: 'export.csv',
          type: SaveFileType.csv,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('calls selector once per getLocation call', () async {
      var callCount = 0;

      final picker = NativeSaveLocationPicker(
        getSaveLocationOverride: ({
          required String suggestedName,
          required List<XTypeGroup> acceptedTypeGroups,
        }) async {
          callCount++;
          return FileSaveLocation('/tmp/export.csv');
        },
      );

      await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(callCount, 1);
    });

    test('calls selector once for each repeated getLocation call', () async {
      var callCount = 0;

      final picker = NativeSaveLocationPicker(
        getSaveLocationOverride: ({
          required String suggestedName,
          required List<XTypeGroup> acceptedTypeGroups,
        }) async {
          callCount++;
          return FileSaveLocation('/tmp/export_$callCount.csv');
        },
      );

      final first = await picker.getLocation(
        suggestedName: 'first.csv',
        type: SaveFileType.csv,
      );

      final second = await picker.getLocation(
        suggestedName: 'second.csv',
        type: SaveFileType.csv,
      );

      expect(callCount, 2);
      expect(first, '/tmp/export_1.csv');
      expect(second, '/tmp/export_2.csv');
    });

    test('uses independent type group objects across calls', () async {
      final capturedGroups = <XTypeGroup>[];

      final picker = NativeSaveLocationPicker(
        getSaveLocationOverride: ({
          required String suggestedName,
          required List<XTypeGroup> acceptedTypeGroups,
        }) async {
          capturedGroups.add(acceptedTypeGroups.single);
          return FileSaveLocation('/tmp/export.csv');
        },
      );

      await picker.getLocation(
        suggestedName: 'first.csv',
        type: SaveFileType.csv,
      );

      await picker.getLocation(
        suggestedName: 'second.csv',
        type: SaveFileType.csv,
      );

      expect(capturedGroups.length, 2);
      expect(identical(capturedGroups[0], capturedGroups[1]), isFalse);
    });

    test('csv json and txt type groups are distinct', () async {
      final capturedGroups = <XTypeGroup>[];

      final picker = NativeSaveLocationPicker(
        getSaveLocationOverride: ({
          required String suggestedName,
          required List<XTypeGroup> acceptedTypeGroups,
        }) async {
          capturedGroups.add(acceptedTypeGroups.single);
          return FileSaveLocation('/tmp/output');
        },
      );

      await picker.getLocation(
        suggestedName: 'data.csv',
        type: SaveFileType.csv,
      );

      await picker.getLocation(
        suggestedName: 'project.json',
        type: SaveFileType.json,
      );

      await picker.getLocation(
        suggestedName: 'data.txt',
        type: SaveFileType.txt,
      );

      expect(capturedGroups[0].label, 'CSV Files');
      expect(capturedGroups[1].label, 'JSON Files');
      expect(capturedGroups[2].label, 'Text Files');

      expect(capturedGroups[0].extensions, ['csv']);
      expect(capturedGroups[1].extensions, ['json']);
      expect(capturedGroups[2].extensions, ['txt']);
    });

    test('returns null when selector returns null even with valid suggested name and type', () async {
      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'project.json',
        type: SaveFileType.json,
      );

      expect(result, isNull);
      expect(capturedSuggestedName, 'project.json');
      expect(capturedAcceptedTypeGroups!.single.extensions, ['json']);
    });

    test('does not require selected path extension to match requested type', () async {
      fakeLocation = FileSaveLocation('/tmp/user_chose_weird_name.weird');

      final picker = createPicker();

      final result = await picker.getLocation(
        suggestedName: 'export.csv',
        type: SaveFileType.csv,
      );

      expect(result, '/tmp/user_chose_weird_name.weird');
    });
  });
}