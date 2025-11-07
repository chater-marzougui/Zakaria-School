import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/structs.dart' as structs;
import '../../helpers/time_utils.dart';
import 'session_block.dart';
import 'session_overlap_calculator.dart';

class DayDetailsScreen extends StatelessWidget {
  final DateTime date;
  final List<structs.Session> sessions;

  const DayDetailsScreen({
    super.key,
    required this.date,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMMM dd, yyyy').format(date)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('candidates').snapshots(),
        builder: (context, candidatesSnapshot) {
          if (!candidatesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final candidatesMap = <String, structs.Candidate>{};
          for (var doc in candidatesSnapshot.data!.docs) {
            final candidate = structs.Candidate.fromFirestore(doc);
            candidatesMap[candidate.id] = candidate;
          }

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: theme.colorScheme.primary.withAlpha(72),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noSessionsThisWeek,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-session');
                    },
                    icon: const Icon(Icons.add),
                    label: Text(t.addSession),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      icon: Icons.event,
                      label: t.totalSessions,
                      value: sessions.length.toString(),
                      theme: theme,
                    ),
                    _SummaryItem(
                      icon: Icons.schedule,
                      label: t.totalHours,
                      value: _calculateTotalHours(sessions).toStringAsFixed(1),
                      theme: theme,
                    ),
                    _SummaryItem(
                      icon: Icons.people,
                      label: t.candidates,
                      value: _getUniqueCandidatesCount(sessions).toString(),
                      theme: theme,
                    ),
                  ],
                ),
              ),

              // Timeline view
              Expanded(
                child: _buildTimelineView(context, candidatesMap, theme),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-session-day-details',
        onPressed: () {
          Navigator.pushNamed(context, '/add-session');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context, Map<String, structs.Candidate> candidatesMap, ThemeData theme) {
    final hourHeight = 80.0;
    final hours = List.generate(13, (index) => 8 + index);
    const baseMinutes = 8 * 60;
    final totalHeight = hours.length * hourHeight;

    final overlaps = SessionOverlapCalculator.calculateOverlaps(sessions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time labels
          SizedBox(
            width: 80,
            child: Column(
              children: hours.map((hour) {
                return Container(
                  height: hourHeight,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Timeline
          Expanded(
            child: Container(
              height: totalHeight,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.dividerColor, width: 2),
                ),
              ),
              child: Stack(
                children: [
                  // Hour dividers
                  ...hours.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Positioned(
                      top: index * hourHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withAlpha(72),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Sessions
                  ...sessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    final overlap = overlaps[index];

                    final startMinutes = TimeUtils.timeToMinutes(session.startTime);
                    final endMinutes = TimeUtils.timeToMinutes(session.endTime);
                    final duration = endMinutes - startMinutes;

                    final topPosition = ((startMinutes - baseMinutes) / 60) * hourHeight;
                    final height = (duration / 60) * hourHeight;

                    // Calculate width for overlaps with more space
                    final availableWidth = MediaQuery.of(context).size.width - 120;
                    final columnWidth = availableWidth / overlap.totalColumns;
                    final leftOffset = overlap.columnIndex * columnWidth;

                    return Positioned(
                      top: topPosition.clamp(0.0, totalHeight),
                      left: leftOffset + 8,
                      child: SessionBlock(
                        session: session,
                        candidate: candidatesMap[session.candidateId],
                        width: columnWidth - 16,
                        height: height.clamp(40.0, totalHeight),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalHours(List<structs.Session> sessions) {
    return sessions.fold(0.0, (sumT, session) => sumT + session.durationInHours);
  }

  int _getUniqueCandidatesCount(List<structs.Session> sessions) {
    return sessions.map((s) => s.candidateId).toSet().length;
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}