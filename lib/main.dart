import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'track_api.dart' hide Row;
import 'log_view.dart';
import 'web_style.dart';
import 'l10n/app_localizations.dart';

typedef Json = Map<String, dynamic>;
const mac = MethodChannel('opentickly/mac');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final language = await mac.invokeMethod<String>('readLanguage');
  runApp(OpenTicklyApp(initialLanguage: language));
}

class OpenTicklyApp extends StatefulWidget {
  final String? initialLanguage;
  final TrackApi Function(Uri, String) client;
  const OpenTicklyApp({
    super.key,
    this.initialLanguage,
    this.client = TrackApi.new,
  });
  @override
  State<OpenTicklyApp> createState() => _OpenTicklyAppState();
}

class _OpenTicklyAppState extends State<OpenTicklyApp> {
  late String? language = widget.initialLanguage;
  Future<void> changeLanguage(String? value) async {
    await mac.invokeMethod('setLanguage', value);
    if (mounted) setState(() => language = value);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OpenTickly',
    debugShowCheckedModeBanner: false,
    theme: webTheme,
    locale: language == null ? null : Locale(language!),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const [Locale('en'), Locale('de')],
    home: Tracker(
      client: widget.client,
      language: language,
      onLanguage: changeLanguage,
    ),
  );
}

class Tracker extends StatefulWidget {
  final TrackApi Function(Uri, String) client;
  final String? language;
  final ValueChanged<String?> onLanguage;
  const Tracker({
    super.key,
    this.client = TrackApi.new,
    this.language,
    required this.onLanguage,
  });
  @override
  State<Tracker> createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> with WidgetsBindingObserver {
  final description = TextEditingController();
  final url = TextEditingController();
  final keyField = TextEditingController();
  final now = ValueNotifier(DateTime.now());
  TrackApi? api;
  int workspace = 0;
  late WorkspaceCatalog catalog;
  List<Json> entries = [];
  Json? active;
  int? project;
  Set<int> selectedTags = {};
  bool billable = false,
      settings = false,
      busy = true,
      syncing = false,
      stale = true;
  Object? error;
  String? badge;
  AppLocalizations get strings => AppLocalizations.of(context)!;
  Timer? ticker, poll;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
      updateDock();
    });
    poll = Timer.periodic(const Duration(seconds: 30), (_) => sync());
    mac.invokeMethod('status');
    restore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sync();
  }

  void updateDock() {
    final e = active;
    final next = e == null ? null : clock(seconds(e, now.value));
    if (next != badge) {
      badge = next;
      mac.invokeMethod('status', next);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker?.cancel();
    poll?.cancel();
    now.dispose();
    description.dispose();
    url.dispose();
    keyField.dispose();
    super.dispose();
  }

  String message(Object e) => switch (e) {
    TrackError() => switch (e.reason) {
      TrackFailure.timerChanged => strings.timerChanged,
      TrackFailure.missingKey => strings.missingKey,
      TrackFailure.invalidAddress => strings.invalidAddress,
      TrackFailure.invalidKey => strings.invalidKey,
      TrackFailure.unreachable => strings.unreachable,
      TrackFailure.timeout => strings.timeout,
      TrackFailure.noWorkspace => strings.noWorkspace,
      TrackFailure.httpError => strings.httpError(e.status.toString()),
    },
    PlatformException() => strings.keychainUnavailable,
    _ => strings.invalidResponse,
  };
  Future<void> restore() async {
    try {
      final raw = await mac.invokeMethod<String>('read');
      if (raw != null) {
        final saved = jsonDecode(raw);
        url.text = saved['url'];
        final candidate = widget.client(
          TrackApi.address(url.text),
          saved['token'],
        );
        await connect(candidate, save: false, savedDefaults: saved['defaults']);
      }
    } catch (e) {
      error = e;
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> connect(
    TrackApi candidate, {
    required bool save,
    Json? savedDefaults,
  }) async {
    final nextCatalog = await candidate.loadCatalog();
    final history = await candidate.history();
    final current = await candidate.current();
    final recent = history.where((e) => e['stop'] != null).toList()
      ..sort(
        (a, b) =>
            DateTime.parse(b['start']).compareTo(DateTime.parse(a['start'])),
      );
    // Old keychain records have no defaults. Seed them from the latest entry.
    final seed =
        savedDefaults ??
        (api?.base == candidate.base && api?.token == candidate.token
            ? defaults
            : (current ?? recent.firstOrNull));
    final nextDefaults = validatedDefaults(nextCatalog, seed);
    if (save || savedDefaults == null) {
      await saveConnection(candidate, nextDefaults);
    }
    api = candidate;
    catalog = nextCatalog;
    useDefaults(nextDefaults);
    apply(history, current);
    description.clear();
    keyField.clear();
    settings = false;
    error = null;
  }

  Json get defaults => {
    'workspace_id': workspace,
    'project_id': project,
    'tag_ids': selectedTags.toList(),
    'billable': billable,
  };

  Json validatedDefaults(WorkspaceCatalog source, Json? input) {
    final requested = workspaceOf(input);
    final wid = source.resolve(requested);
    final sameWorkspace = wid == requested;
    final pid = input?['project_id'] ?? input?['pid'];
    final ids = input?['tag_ids'] as List? ?? [];
    final names = input?['tags'] as List? ?? [];
    return {
      'workspace_id': wid,
      'project_id':
          sameWorkspace && source.projectsFor(wid).any((p) => p['id'] == pid)
          ? pid
          : null,
      'tag_ids': [
        if (sameWorkspace)
          for (final tag in source.tagsFor(wid))
            if (ids.contains(tag['id']) ||
                (ids.isEmpty && names.contains(tag['name'])))
              tag['id'],
      ],
      'billable': input?['billable'] == true,
    };
  }

  void useDefaults(Json values) {
    workspace = values['workspace_id'];
    project = values['project_id'];
    selectedTags = (values['tag_ids'] as List).cast<int>().toSet();
    billable = values['billable'];
  }

  Future<void> saveConnection(TrackApi client, Json selection) =>
      mac.invokeMethod(
        'save',
        jsonEncode({
          'url': client.base.toString(),
          'token': client.token,
          'defaults': selection,
        }),
      );

  Future<void> changeDefaults(VoidCallback change) async {
    final client = api!;
    setState(change);
    try {
      await saveConnection(client, defaults);
    } catch (e) {
      if (mounted && identical(client, api)) setState(() => error = e);
    }
  }

  void apply(List<Json> history, Json? current) {
    active = current;
    entries = [
      ?current,
      ...history.where((e) => e['stop'] != null && e['id'] != current?['id']),
    ];
    entries.sort(
      (a, b) =>
          DateTime.parse(b['start']).compareTo(DateTime.parse(a['start'])),
    );
    stale = false;
    updateDock();
  }

  Future<void> sync({bool full = false, bool preserveError = false}) async {
    final a = api;
    if (a == null || busy || syncing) return;
    setState(() => syncing = true);
    try {
      final nextCatalog = full ? await a.loadCatalog() : null;
      final history = await a.history(), current = await a.current();
      if (identical(a, api)) {
        setState(() {
          if (nextCatalog != null) {
            catalog = nextCatalog;
            useDefaults(validatedDefaults(catalog, defaults));
          }
          apply(history, current);
          if (!preserveError && !settings) error = null;
        });
        if (full) await saveConnection(a, defaults);
      }
    } catch (e) {
      setState(() {
        error = e;
        stale = true;
      });
    } finally {
      setState(() => syncing = false);
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy || syncing) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      error = e;
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> toggle({Json? resumeEntry}) async {
    final a = api!;
    await run(() async {
      stale = true;
      final current = await a.current();
      if (current?['id'] != active?['id']) {
        apply(await a.history(), current);
        throw TrackError(TrackFailure.timerChanged);
      }
      if (resumeEntry != null) {
        active = await a.resume(resumeEntry);
      } else if (current == null) {
        active = await a.start(
          workspace,
          description.text.trim(),
          project,
          selectedTags,
          billable,
        );
        description.clear();
      } else {
        await a.stop(current);
        active = null;
      }
      updateDock();
      if (resumeEntry != null ||
          (current != null && workspaceOf(current) == workspace)) {
        useDefaults(validatedDefaults(catalog, resumeEntry ?? current));
        await saveConnection(a, defaults);
      }
      apply(await a.history(), await a.current());
    });
    if (stale) await sync(preserveError: true);
  }

  Widget login() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            settings ? strings.settings : strings.signIn,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(strings.language),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                borderRadius: Pill.radius,
                tooltip: strings.language,
                onSelected: (value) =>
                    widget.onLanguage(value == 'system' ? null : value),
                itemBuilder: (_) => [
                  for (final option in {
                    'system': strings.systemLanguage,
                    'en': 'English',
                    'de': 'Deutsch',
                  }.entries)
                    PopupMenuItem(
                      value: option.key,
                      child: MenuLabel(
                        option.value,
                        selected: option.key == (widget.language ?? 'system'),
                      ),
                    ),
                ],
                child: Pill(Icons.language, switch (widget.language) {
                  'de' => 'Deutsch',
                  'en' => 'English',
                  _ => strings.systemLanguage,
                }, false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: url,
            decoration: InputDecoration(
              labelText: strings.serverUrl,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: keyField,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: settings ? strings.newApiKey : strings.apiKey,
              border: const OutlineInputBorder(),
              helperText: strings.apiHint,
            ),
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              shadows: busy || syncing
                  ? null
                  : const [
                      BoxShadow(color: accentStrong, offset: Offset(0, 4)),
                    ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: busy || syncing
                  ? null
                  : () => run(() async {
                      if (keyField.text.trim().isEmpty) {
                        throw TrackError(TrackFailure.missingKey);
                      }
                      await connect(
                        widget.client(
                          TrackApi.address(url.text),
                          keyField.text.trim(),
                        ),
                        save: true,
                      );
                    }),
              child: Text(
                busy
                    ? strings.connecting
                    : settings
                    ? strings.saveConnection
                    : strings.connect,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (settings)
            TextButton(
              onPressed: busy || syncing
                  ? null
                  : () => run(() async {
                      await mac.invokeMethod('delete');
                      api = null;
                      active = null;
                      entries = [];
                      settings = false;
                      keyField.clear();
                      description.clear();
                      updateDock();
                    }),
              child: Text(strings.signOut),
            ),
        ],
      ),
    );
  }

  Future<void> switchWorkspace(int id) async {
    if (workspace == id) return;
    final client = api!;
    await run(() async {
      final fresh = await Future.wait([
        client.catalog('projects', workspace: id),
        client.catalog('tags', workspace: id),
        client.history(),
      ]);
      final current = await client.current();
      final next = WorkspaceCatalog(
        catalog.defaultId,
        catalog.workspaces,
        [...catalog.projects.where((p) => workspaceOf(p) != id), ...fresh[0]],
        [...catalog.tags.where((t) => workspaceOf(t) != id), ...fresh[1]],
        catalog.organizations,
      );
      final selection = validatedDefaults(next, {
        'workspace_id': id,
        'billable': billable,
      });
      await saveConnection(client, selection);
      catalog = next;
      useDefaults(selection);
      apply(fresh[2], current);
    });
  }

  Widget composer() {
    final e = workspaceOf(active) == workspace ? active : null;
    final locked = busy || e != null;
    final displayedWorkspace = workspaceOf(e) ?? workspace;
    final projects = catalog.projectsFor(displayedWorkspace);
    final activeTags = catalog.tagsFor(displayedWorkspace);
    final pid = e == null ? project : e['project_id'] ?? e['pid'];
    final pname =
        e?['project_name'] ??
        projects.where((p) => p['id'] == pid).firstOrNull?['name'];
    final tagNames = e == null
        ? activeTags
              .where((t) => selectedTags.contains(t['id']))
              .map((t) => t['name'])
              .toList()
        : e['tags'] as List? ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: e != null
                    ? Text(
                        (e['description'] as String? ?? '').isEmpty
                            ? strings.withoutDescription
                            : e['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17),
                      )
                    : TextField(
                        controller: description,
                        enabled: !busy,
                        decoration: InputDecoration(
                          filled: false,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: strings.workingOn,
                          border: InputBorder.none,
                        ),
                      ),
              ),
              ValueListenableBuilder(
                valueListenable: now,
                builder: (_, date, _) => Text(
                  clock(e == null ? 0 : seconds(e, date)),
                  style: digits.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (e == null)
                PlayButton(
                  tooltip: strings.startTimer,
                  onPressed: busy || syncing || stale || active != null
                      ? null
                      : toggle,
                )
              else
                RaisedCircle(
                  tooltip: strings.stopTimer,
                  onPressed: busy || syncing || stale ? null : toggle,
                  fill: const Color(0xffd92d20),
                  depth: const Color(0xff912018),
                  foreground: Colors.white,
                  icon: const Icon(Icons.stop_rounded),
                  size: 44,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (projects.isEmpty && pname == null)
                  EmptyChoice(Icons.folder_open_outlined, strings.emptyProjects)
                else
                  PopupMenuButton<int>(
                    borderRadius: Pill.radius,
                    enabled: !locked,
                    tooltip: strings.chooseProject,
                    onSelected: (id) {
                      if (workspaceOf(active) != workspace &&
                          (id == 0 ||
                              catalog
                                  .projectsFor(workspace)
                                  .any((p) => p['id'] == id))) {
                        changeDefaults(() => project = id == 0 ? null : id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 0,
                        child: MenuLabel(
                          strings.noProject,
                          selected: pid == null,
                        ),
                      ),
                      ...projects.map(
                        (p) => PopupMenuItem<int>(
                          value: p['id'],
                          child: MenuLabel(p['name'], selected: pid == p['id']),
                        ),
                      ),
                    ],
                    child: Pill(
                      Icons.folder_open_outlined,
                      pname ?? strings.project,
                      pid != null,
                    ),
                  ),
                if (activeTags.isEmpty && tagNames.isEmpty)
                  EmptyChoice(Icons.sell_outlined, strings.emptyTags)
                else
                  _TagMenu(
                    key: ValueKey((workspace, active?['id'])),
                    items: activeTags,
                    selected: selectedTags,
                    enabled: !locked,
                    label: tagNames.isEmpty
                        ? strings.tags
                        : tagNames.join(', '),
                    onToggle: (id) => changeDefaults(() {
                      if (!selectedTags.remove(id)) selectedTags.add(id);
                    }),
                  ),
                Semantics(
                  toggled: e?['billable'] ?? billable,
                  child: IconButton(
                    tooltip: strings.billable,
                    onPressed: locked
                        ? null
                        : () => changeDefaults(() => billable = !billable),
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                    icon: Text(
                      r'$',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: (e?['billable'] ?? billable) ? accent : muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffe05d26),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const ExcludeSemantics(
                    child: Text(
                      't',
                      style: TextStyle(
                        color: ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'OpenTickly',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (api != null && !settings) ...[
                  RaisedCircle(
                    tooltip: strings.syncAll,
                    onPressed: busy || syncing ? null : () => sync(full: true),
                    icon: syncing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
                if (api != null &&
                    !settings &&
                    catalog.workspaces.length > 1) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 148,
                      minHeight: toolbarButtonHeight,
                      maxHeight: toolbarButtonHeight,
                    ),
                    child: PopupMenuButton<int>(
                      borderRadius: Pill.radius,
                      tooltip: strings.chooseWorkspace,
                      enabled: !busy && !syncing,
                      onSelected: switchWorkspace,
                      itemBuilder: (_) => [
                        for (final w in catalog.workspaces)
                          PopupMenuItem<int>(
                            value: w['id'],
                            child: MenuLabel(
                              catalog.label(w['id']),
                              selected: w['id'] == workspace,
                            ),
                          ),
                      ],
                      child: Pill(
                        Icons.workspaces_outline,
                        catalog.label(workspace),
                        false,
                        edgeHeight: busy || syncing ? 0 : toolbarButtonDepth,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (api != null)
                  RaisedCircle(
                    tooltip: settings ? strings.backToTimer : strings.settings,
                    onPressed: busy || syncing
                        ? null
                        : () => setState(() {
                            settings = !settings;
                            error = null;
                            keyField.clear();
                            url.text = api!.base.toString().replaceFirst(
                              RegExp(r'/api/v9/$'),
                              '',
                            );
                          }),
                    icon: Icon(
                      settings ? Icons.close : Icons.settings_outlined,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (error != null)
            Container(
              color: const Color(0xffffede9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text(message(error!))),
                  if (api != null && !settings)
                    TextButton(
                      onPressed: busy || syncing
                          ? null
                          : () => sync(full: true),
                      child: Text(strings.refresh),
                    ),
                ],
              ),
            ),
          if (settings || api == null)
            Expanded(child: login())
          else ...[
            if (active != null && workspaceOf(active) != workspace)
              ListTile(
                dense: true,
                title: Text(
                  strings.runningIn(catalog.label(workspaceOf(active))),
                ),
                trailing: IconButton(
                  tooltip: strings.stopTimer,
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: busy || syncing || stale ? null : toggle,
                ),
              ),
            Material(color: canvas, child: composer()),
            const Divider(height: 1),
            Expanded(
              child: EntryLog(
                entries
                    .where((entry) => workspaceOf(entry) == workspace)
                    .toList(),
                active?['id'],
                now,
                catalog: catalog,
                onResume: busy || syncing || stale
                    ? null
                    : (entry) => toggle(resumeEntry: entry),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class Pill extends StatelessWidget {
  static const radius = BorderRadius.all(Radius.circular(18));
  final IconData icon;
  final String label;
  final bool selected, disabled;
  final double edgeHeight;
  const Pill(
    this.icon,
    this.label,
    this.selected, {
    this.disabled = false,
    this.edgeHeight = 2,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Ink(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: disabled ? Colors.transparent : canvas,
      border: disabled ? null : Border.all(color: webBorder),
      borderRadius: Pill.radius,
      boxShadow: disabled || edgeHeight == 0
          ? null
          : [BoxShadow(color: webBorder, offset: Offset(0, edgeHeight))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: selected ? plum : muted),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: selected ? plum : muted),
            ),
          ),
        ],
        if (!disabled) const Icon(Icons.expand_more, size: 15, color: muted),
      ],
    ),
  );
}

class EmptyChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  const EmptyChoice(this.icon, this.label, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    enabled: false,
    button: true,
    child: Opacity(
      opacity: 0.6,
      child: Pill(icon, label, false, disabled: true),
    ),
  );
}

class _TagMenu extends StatefulWidget {
  final Iterable<Json> items;
  final Set<int> selected;
  final String label;
  final bool enabled;
  final ValueChanged<int> onToggle;
  const _TagMenu({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.enabled,
    required this.onToggle,
  });
  @override
  State<_TagMenu> createState() => _TagMenuState();
}

class _TagMenuState extends State<_TagMenu> {
  final buttonFocus = FocusNode();
  final firstTagFocus = FocusNode();

  @override
  void dispose() {
    buttonFocus.dispose();
    firstTagFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: buttonFocus,
      onOpen: firstTagFocus.requestFocus,
      alignmentOffset: const Offset(0, 5),
      menuChildren: [
        for (final tag in widget.items)
          CheckboxMenuButton(
            focusNode: tag == widget.items.first ? firstTagFocus : null,
            style: MenuItemButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            closeOnActivate: false,
            value: widget.selected.contains(tag['id']),
            onChanged: widget.enabled
                ? (_) => widget.onToggle(tag['id'])
                : null,
            child: Text(
              tag['name'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      builder: (context, menu, _) => InkWell(
        borderRadius: Pill.radius,
        focusNode: buttonFocus,
        onTap: widget.enabled ? (menu.isOpen ? menu.close : menu.open) : null,
        child: Pill(
          Icons.sell_outlined,
          widget.label,
          widget.selected.isNotEmpty,
        ),
      ),
    );
  }
}
