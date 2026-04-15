import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ui_prototype/application/device_storage/device_storage.dart';

class FakeSecureStorage implements DeviceStorage {

  // Define dict for fake secure storage
  final Map<String, String> _store = {};

  // Override the read method
  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    
    // Return from store dictionary
    return _store[key];
  }

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {

    // If value is null
    if (value == null) {

      // Remove the value
      _store.remove(key);
    }

    // Otherwise
    else {

      // Store passed in value
      _store[key] = value;
    }

    // Return nothing
    return;
  }

  // Throw error for unused methods
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}