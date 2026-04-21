//enum that lists all the sounds that will be used in the app
//each one represents a app event
enum AppSound 
{
  readerDiscovered,
  tagAccepted,
  tagHistoryFound,
  tagHistoryDiff,
  tagIgnored,
  tagDuplicate,
  recordSavedOk,
  recordSaveFailed,
}

//extension to provide display labels for each AppSound.
extension AppSoundPresentation on AppSound {
  String get label {
    switch (this) {
      case AppSound.readerDiscovered:
        return 'Reader Discovered';
      case AppSound.tagAccepted:
        return 'Tag Accepted';
      case AppSound.tagHistoryFound:
        return 'Tag History Found';
      case AppSound.tagHistoryDiff:
        return 'Tag History Diff';
      case AppSound.tagIgnored:
        return 'Tag Ignored';
      case AppSound.tagDuplicate:
        return 'Tag Duplicate';
      case AppSound.recordSavedOk:
        return 'Record Saved OK';
      case AppSound.recordSaveFailed:
        return 'Record Save Failed';
    }
  }
}