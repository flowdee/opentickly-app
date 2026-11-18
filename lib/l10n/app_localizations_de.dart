// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get serverUrl => 'URL der OpenTickly-Installation';

  @override
  String get newApiKey => 'Neuer API-Key';

  @override
  String get apiKey => 'API-Key';

  @override
  String get apiHint => 'OpenTickly → Profil → API Token';

  @override
  String get connecting => 'Verbinde …';

  @override
  String get saveConnection => 'Verbindung speichern';

  @override
  String get connect => 'Verbinden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get withoutDescription => 'Ohne Beschreibung';

  @override
  String get workingOn => 'Woran arbeitest du?';

  @override
  String get startTimer => 'Timer starten';

  @override
  String get stopTimer => 'Timer stoppen';

  @override
  String get chooseWorkspace => 'Workspace auswählen';

  @override
  String get chooseProject => 'Projekt auswählen';

  @override
  String get emptyProjects => 'Keine Projekte vorhanden';

  @override
  String get emptyTags => 'Keine Tags vorhanden';

  @override
  String get noProject => 'Ohne Projekt';

  @override
  String get project => 'Projekt';

  @override
  String get tags => 'Tags';

  @override
  String get noTags => 'Ohne Tags';

  @override
  String get billable => 'Abrechenbar';

  @override
  String get nonBillable => 'Nicht abrechenbar';

  @override
  String get syncAll => 'Alles synchronisieren';

  @override
  String get backToTimer => 'Zurück zum Timer';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get apply => 'Übernehmen';

  @override
  String get emptyEntries => 'Noch keine Zeiteinträge.';

  @override
  String get resumeEntry => 'Eintrag fortsetzen';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get keychainUnavailable => 'Schlüsselbund nicht verfügbar.';

  @override
  String get invalidResponse => 'Antwort konnte nicht verarbeitet werden.';

  @override
  String get timerChanged => 'Der Timer wurde zwischenzeitlich geändert. Ansicht aktualisiert.';

  @override
  String get missingKey => 'Bitte den API-Key eingeben.';

  @override
  String get invalidAddress => 'Bitte die HTTPS-Adresse deiner Installation eingeben.';

  @override
  String get invalidKey => 'API-Key ungültig. Bitte erneut anmelden.';

  @override
  String get unreachable => 'Server nicht erreichbar. Bitte Verbindung und URL prüfen.';

  @override
  String get timeout => 'Der Server antwortet nicht rechtzeitig.';

  @override
  String get noWorkspace => 'Kein Workspace verfügbar.';

  @override
  String httpError(String code) {
    return 'OpenTickly meldet HTTP $code. Bitte URL und Zugriff prüfen.';
  }

  @override
  String runningIn(String name) {
    return 'Timer läuft in $name';
  }

  @override
  String projectId(String id) {
    return 'Projekt #$id';
  }

  @override
  String tagId(String id) {
    return 'Tag #$id';
  }
}
