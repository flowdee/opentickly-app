import 'package:flutter/material.dart';

import 'track_api.dart' show seconds, clock, WorkspaceCatalog, workspaceOf;

import 'web_style.dart';
import 'l10n/app_localizations.dart';

import 'package:intl/intl.dart';

const digits = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
  fontWeight: FontWeight.w600,
);

class EntryLog extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final int? runningId;
  final WorkspaceCatalog catalog;
  final ValueNotifier<DateTime> now;
  final ValueChanged<Map<String, dynamic>>? onResume;
  const EntryLog(
    this.entries,
    this.runningId,
    this.now, {
    required this.onResume,
    required this.catalog,
    super.key,
  });

  String dayLabel(BuildContext context, DateTime day) {
    final today = DateUtils.dateOnly(now.value);
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final prefix = day == today
        ? strings.today
        : day == DateTime(today.year, today.month, today.day - 1)
        ? strings.yesterday
        : DateFormat.E(locale).format(day);
    return '$prefix · ${DateFormat.yMd(locale).format(day)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      return Center(
        child: Text(strings.emptyEntries, style: const TextStyle(color: muted)),
      );
    }
    final rows = <Widget>[];
    int i = 0;
    while (i < entries.length) {
      final day = DateUtils.dateOnly(
        DateTime.parse(entries[i]['start']).toLocal(),
      );
      var end = i;
      int total = 0;
      Map<String, dynamic>? active;
      while (end < entries.length &&
          DateUtils.isSameDay(
            day,
            DateTime.parse(entries[end]['start']).toLocal(),
          )) {
        final e = entries[end++];
        if (e['id'] == runningId) {
          active = e;
        } else {
          total += seconds(e, now.value);
        }
      }
      final live = active;
      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(color: canvas),
          child: RowLayout(
            left: Text(
              dayLabel(context, day),
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            right: live == null
                ? Text(clock(total), style: digits)
                : ValueListenableBuilder(
                    valueListenable: now,
                    builder: (_, date, _) =>
                        Text(clock(total + seconds(live, date)), style: digits),
                  ),
          ),
        ),
      );
      for (; i < end; i++) {
        final entry = entries[i];
        final label = (entry['description'] as String? ?? '').trim();
        final pid = entry['project_id'] ?? entry['pid'];
        final project = catalog.projects
            .where(
              (p) => p['id'] == pid && workspaceOf(p) == workspaceOf(entry),
            )
            .firstOrNull;
        final projectLabel =
            entry['project_name'] ??
            project?['name'] ??
            (pid == null
                ? strings.noProject
                : strings.projectId(pid.toString()));
        final tagIds = entry['tag_ids'] as List? ?? [];
        final names = (entry['tags'] as List? ?? [])
            .whereType<String>()
            .toSet();
        if (names.isEmpty) {
          for (final id in tagIds) {
            final tag = catalog.tags
                .where(
                  (t) => t['id'] == id && workspaceOf(t) == workspaceOf(entry),
                )
                .firstOrNull;
            names.add(tag?['name'] ?? strings.tagId(id.toString()));
          }
        }
        final meta = [
          projectLabel,
          if (entry['client_name'] != null) entry['client_name'],
          names.isEmpty ? strings.noTags : names.join(', '),
          entry['billable'] == true ? strings.billable : strings.nonBillable,
        ].join(' · ');
        rows.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: entry['id'] == runningId ? accentSoft : Colors.white,
              border: const Border(bottom: BorderSide(color: softBorder)),
            ),
            child: RowLayout(
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.isEmpty ? strings.withoutDescription : label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
              right: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (entry['id'] == runningId)
                        ValueListenableBuilder(
                          valueListenable: now,
                          builder: (_, date, _) => Text(
                            clock(seconds(entry, date)),
                            style: digits.copyWith(color: plum),
                          ),
                        )
                      else
                        Text(clock(seconds(entry, now.value)), style: digits),
                    ],
                  ),
                  if (entry['id'] != runningId) ...[
                    const SizedBox(width: 10),
                    PlayButton(
                      size: 28,
                      tooltip: strings.resumeEntry,
                      onPressed: onResume == null
                          ? null
                          : () => onResume!(entry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }
}

class RowLayout extends StatelessWidget {
  final Widget left, right;
  const RowLayout({super.key, required this.left, required this.right});
  @override
  Widget build(BuildContext context) => Flex(
    direction: Axis.horizontal,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      right,
    ],
  );
}
