import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef Row = Map<String, dynamic>;

enum TrackFailure {
  timerChanged,
  missingKey,
  invalidAddress,
  invalidKey,
  unreachable,
  timeout,
  noWorkspace,
  httpError,
}

class TrackError implements Exception {
  final TrackFailure reason;
  final int? status;
  TrackError(this.reason, {this.status});
}

class TrackApi {
  final Uri base;
  final String token;
  TrackApi(this.base, this.token);

  static Uri address(String input) {
    var text = input.trim();
    if (!text.contains('://')) text = 'https://$text';
    final uri = Uri.tryParse(text);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw TrackError(TrackFailure.invalidAddress);
    }
    var path = uri.path.replaceAll(RegExp(r'/+$'), '');
    if (!path.endsWith('/api/v9')) path += '/api/v9';
    return uri.replace(path: '$path/');
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Row? body,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final req = await client.openUrl(method, base.resolve(path));
        req.followRedirects = false;
        req.headers.set(
          'Authorization',
          'Basic ${base64Encode(utf8.encode('$token:api_token'))}',
        );
        if (body != null) {
          req.headers.contentType = ContentType.json;
          req.write(jsonEncode(body));
        }
        final response = await req.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (response.statusCode == 401) {
            throw TrackError(TrackFailure.invalidKey);
          }
          throw TrackError(TrackFailure.httpError, status: response.statusCode);
        }
        final raw = await utf8.decoder.bind(response).join();
        return raw.isEmpty ? null : jsonDecode(raw);
      })().timeout(const Duration(seconds: 20));
    } on IOException {
      throw TrackError(TrackFailure.unreachable);
    } on TimeoutException {
      throw TrackError(TrackFailure.timeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Row>> list(String path) async =>
      ((await request(path)) as List).cast<Row>();
  Future<List<Row>> catalog(String name, {int? workspace}) async {
    final items = <int, Row>{};
    for (var page = 1; ; page++) {
      final scope = workspace == null ? 'me' : 'workspaces/$workspace';
      final batch = await list('$scope/$name?page=$page&per_page=200');
      final oldSize = items.length;
      for (final row in batch) {
        items[row['id'] as int] = row;
      }
      if (batch.length < 200 || items.length == oldSize) break;
    }
    return items.values.toList()..sort(
      (a, b) => (a['name'] as String).toLowerCase().compareTo(
        (b['name'] as String).toLowerCase(),
      ),
    );
  }

  Future<WorkspaceCatalog> loadCatalog() async {
    final me = await request('me');
    final lists = await Future.wait([
      list('me/workspaces'),
      catalog('projects'),
      catalog('tags'),
      list('me/organizations'),
    ]);
    return WorkspaceCatalog(
      me['default_workspace_id'],
      lists[0],
      lists[1],
      lists[2],
      lists[3],
    );
  }

  Future<Row?> current() async =>
      await request('me/time_entries/current') as Row?;
  Future<List<Row>> history() async => list('me/time_entries');
  Future<Row> start(
    int workspace,
    String description,
    int? project,
    Set<int> tags,
    bool billable, {
    int? taskId,
    List<String> tagNames = const [],
  }) async => await request(
    'workspaces/$workspace/time_entries',
    method: 'POST',
    body: {
      'created_with': 'OpenTickly for Mac',
      'workspace_id': workspace,
      'start': DateTime.now().toUtc().toIso8601String(),
      'duration': -1,
      'description': description,
      'project_id': ?project,
      if (tags.isEmpty && tagNames.isNotEmpty)
        'tags': tagNames
      else
        'tag_ids': tags.toList(),
      'task_id': ?taskId,
      'billable': billable,
    },
  ) as Row;
  Future<Row> resume(Row entry) => start(
    entry['workspace_id'] ?? entry['wid'],
    entry['description'] ?? '',
    entry['project_id'] ?? entry['pid'],
    (entry['tag_ids'] as List? ?? []).cast<int>().toSet(),
    entry['billable'] == true,
    taskId: entry['task_id'] ?? entry['tid'],
    tagNames: (entry['tags'] as List? ?? []).cast<String>(),
  );

  Future<void> stop(Row entry) async {
    await request(
      'workspaces/${entry['workspace_id'] ?? entry['wid']}/time_entries/${entry['id']}/stop',
      method: 'PATCH',
    );
  }
}

int? workspaceOf(Row? row) => row?['workspace_id'] ?? row?['wid'];

class WorkspaceCatalog {
  final int? defaultId;
  final List<Row> workspaces, projects, tags, organizations;
  WorkspaceCatalog(
    this.defaultId,
    this.workspaces,
    this.projects,
    this.tags,
    this.organizations,
  ) {
    if (workspaces.isEmpty) throw TrackError(TrackFailure.noWorkspace);
  }

  String label(int? id) {
    final w = workspaces.where((row) => row['id'] == id).firstOrNull;
    if (w == null) return 'Workspace';
    final oid = w['organization_id'];
    final org = organizations
        .where((row) => row['id'] == oid)
        .firstOrNull?['name'];
    if (org == null || org == '') return w['name'];
    if (workspaces.where((row) => row['organization_id'] == oid).length > 1) {
      return "$org · ${w['name']}";
    }
    return org;
  }

  int resolve(int? preferred) {
    for (final id in [preferred, defaultId]) {
      if (id != null && workspaces.any((w) => w['id'] == id)) return id;
    }
    return workspaces.first['id'] as int;
  }

  Iterable<Row> projectsFor(int workspace) => projects.where(
    (p) => workspaceOf(p) == workspace && p['active'] != false,
  );

  Iterable<Row> tagsFor(int workspace) =>
      tags.where((t) => workspaceOf(t) == workspace);
}

int seconds(Row entry, DateTime now) {
  final duration = entry['duration'] as int? ?? -1;
  if (duration >= 0) return duration;
  return now
      .difference(DateTime.parse(entry['start']))
      .inSeconds
      .clamp(0, 1 << 40);
}

String clock(int seconds) =>
    '${seconds ~/ 3600}:${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
