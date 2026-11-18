import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'OpenTickly installation URL'**
  String get serverUrl;

  /// No description provided for @newApiKey.
  ///
  /// In en, this message translates to:
  /// **'New API key'**
  String get newApiKey;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @apiHint.
  ///
  /// In en, this message translates to:
  /// **'OpenTickly → Profile → API Token'**
  String get apiHint;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @saveConnection.
  ///
  /// In en, this message translates to:
  /// **'Save connection'**
  String get saveConnection;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @withoutDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get withoutDescription;

  /// No description provided for @workingOn.
  ///
  /// In en, this message translates to:
  /// **'What are you working on?'**
  String get workingOn;

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get startTimer;

  /// No description provided for @stopTimer.
  ///
  /// In en, this message translates to:
  /// **'Stop timer'**
  String get stopTimer;

  /// No description provided for @chooseWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Choose workspace'**
  String get chooseWorkspace;

  /// No description provided for @chooseProject.
  ///
  /// In en, this message translates to:
  /// **'Choose project'**
  String get chooseProject;

  /// No description provided for @emptyProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects available'**
  String get emptyProjects;

  /// No description provided for @emptyTags.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get emptyTags;

  /// No description provided for @noProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get noProject;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @billable.
  ///
  /// In en, this message translates to:
  /// **'Billable'**
  String get billable;

  /// No description provided for @nonBillable.
  ///
  /// In en, this message translates to:
  /// **'Non-billable'**
  String get nonBillable;

  /// No description provided for @syncAll.
  ///
  /// In en, this message translates to:
  /// **'Sync all'**
  String get syncAll;

  /// No description provided for @backToTimer.
  ///
  /// In en, this message translates to:
  /// **'Back to timer'**
  String get backToTimer;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @emptyEntries.
  ///
  /// In en, this message translates to:
  /// **'No time entries yet.'**
  String get emptyEntries;

  /// No description provided for @resumeEntry.
  ///
  /// In en, this message translates to:
  /// **'Resume entry'**
  String get resumeEntry;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @keychainUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Keychain unavailable.'**
  String get keychainUnavailable;

  /// No description provided for @invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Could not process the server response.'**
  String get invalidResponse;

  /// No description provided for @timerChanged.
  ///
  /// In en, this message translates to:
  /// **'The timer changed elsewhere. Your view has been refreshed.'**
  String get timerChanged;

  /// No description provided for @missingKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter your API key.'**
  String get missingKey;

  /// No description provided for @invalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the HTTPS address of your installation.'**
  String get invalidAddress;

  /// No description provided for @invalidKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key. Please sign in again.'**
  String get invalidKey;

  /// No description provided for @unreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable. Check the connection and URL.'**
  String get unreachable;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'The server did not respond in time.'**
  String get timeout;

  /// No description provided for @noWorkspace.
  ///
  /// In en, this message translates to:
  /// **'No workspace available.'**
  String get noWorkspace;

  /// No description provided for @httpError.
  ///
  /// In en, this message translates to:
  /// **'OpenTickly returned HTTP {code}. Check the URL and your access.'**
  String httpError(String code);

  /// No description provided for @runningIn.
  ///
  /// In en, this message translates to:
  /// **'Timer running in {name}'**
  String runningIn(String name);

  /// No description provided for @projectId.
  ///
  /// In en, this message translates to:
  /// **'Project #{id}'**
  String projectId(String id);

  /// No description provided for @tagId.
  ///
  /// In en, this message translates to:
  /// **'Tag #{id}'**
  String tagId(String id);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
