// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get signIn => 'Sign in';

  @override
  String get serverUrl => 'OpenTickly installation URL';

  @override
  String get newApiKey => 'New API key';

  @override
  String get apiKey => 'API key';

  @override
  String get apiHint => 'OpenTickly → Profile → API Token';

  @override
  String get connecting => 'Connecting…';

  @override
  String get saveConnection => 'Save connection';

  @override
  String get connect => 'Connect';

  @override
  String get signOut => 'Sign out';

  @override
  String get withoutDescription => 'No description';

  @override
  String get workingOn => 'What are you working on?';

  @override
  String get startTimer => 'Start timer';

  @override
  String get stopTimer => 'Stop timer';

  @override
  String get chooseWorkspace => 'Choose workspace';

  @override
  String get chooseProject => 'Choose project';

  @override
  String get emptyProjects => 'No projects available';

  @override
  String get emptyTags => 'No tags available';

  @override
  String get noProject => 'No project';

  @override
  String get project => 'Project';

  @override
  String get tags => 'Tags';

  @override
  String get noTags => 'No tags';

  @override
  String get billable => 'Billable';

  @override
  String get nonBillable => 'Non-billable';

  @override
  String get syncAll => 'Sync all';

  @override
  String get backToTimer => 'Back to timer';

  @override
  String get refresh => 'Refresh';

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get emptyEntries => 'No time entries yet.';

  @override
  String get resumeEntry => 'Resume entry';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get keychainUnavailable => 'Keychain unavailable.';

  @override
  String get invalidResponse => 'Could not process the server response.';

  @override
  String get timerChanged => 'The timer changed elsewhere. Your view has been refreshed.';

  @override
  String get missingKey => 'Please enter your API key.';

  @override
  String get invalidAddress => 'Enter the HTTPS address of your installation.';

  @override
  String get invalidKey => 'Invalid API key. Please sign in again.';

  @override
  String get unreachable => 'Server unreachable. Check the connection and URL.';

  @override
  String get timeout => 'The server did not respond in time.';

  @override
  String get noWorkspace => 'No workspace available.';

  @override
  String httpError(String code) {
    return 'OpenTickly returned HTTP $code. Check the URL and your access.';
  }

  @override
  String runningIn(String name) {
    return 'Timer running in $name';
  }

  @override
  String projectId(String id) {
    return 'Project #$id';
  }

  @override
  String tagId(String id) {
    return 'Tag #$id';
  }
}
