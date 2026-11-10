import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import '../domain/next_class.dart';
import '../domain/notice_logic.dart';
import 'campus_info_sheet.dart';
import 'event_bar.dart';
import 'exams_page.dart';
import 'notice_card.dart';

/// A home shortcut that opens an existing feature page.
class HomeShortcut {
  const HomeShortcut({
    required this.label,
    required this.icon,
    required this.pageBuilder,
  });

  final String label;
  final IconData icon;
  final Widget Function() pageBuilder;

  void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(context.tr(label))),
          body: pageBuilder(),
        ),
      ),
    );
  }
}

/// Royal Emerald dashboard. Data continues to come from the live repository.
class CampusHomePage extends StatefulWidget {
  const CampusHomePage({
    super.key,
    required this.user,
    required this.repository,
    this.shortcuts = const [],
  });

  final AppUser user;
  final CampusRepository repository;
  final List<HomeShortcut> shortcuts;

  @override
  State<CampusHomePage> createState() => _CampusHomePageState();
}

class _CampusHomePageState extends State<CampusHomePage> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  static const _green = Color(0xFF075B36);
  static const _deepGreen = Color(0xFF034326);
  static const _gold = Color(0xFFFFC629);
  static const _page = Color(0xFFF7F9F7);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user.role == UserRole.student;
    final department = widget.user.department?.trim();

    final courseLine = [
      if (department != null && department.isNotEmpty) department,
      if (widget.user.level != null) 'Level ${widget.user.level}',
    ].join(' • ');

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, courseLine, isStudent),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StreamView<List<ClassSlot>>(
                          open: () =>
                              widget.repository.watchTimetable(widget.user),
                          builder: (context, slots) => StreamView<List<Campus>>(
                            open: widget.repository.watchCampuses,
                            builder: (context, campuses) => _NextClassCard(
                              next: findNextClass(slots, _now),
                              now: _now,
                              campuses: campuses,
                              isLecturer: widget.user.role == UserRole.lecturer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _sectionHeading(context, 'Quick Access'),
                        const SizedBox(height: 12),
                        _shortcutGrid(context),

                        const SizedBox(height: 22),
                        _sectionHeading(context, 'Upcoming events'),
                        const SizedBox(height: 10),

                        StreamView<List<Notice>>(
                          open: widget.repository.watchNotices,
                          builder: (context, notices) => EventBar(
                            events: upcomingEvents(
                              visibleNotices(notices, widget.user),
                              _now,
                            ),
                            now: _now,
                          ),
                        ),

                        const SizedBox(height: 20),
                        NextExamSection(
                          user: widget.user,
                          repository: widget.repository,
                          now: _now,
                        ),

                        const SizedBox(height: 22),
                        _sectionHeading(context, 'Latest notices'),
                        const SizedBox(height: 10),

                        StreamView<List<Notice>>(
                          open: widget.repository.watchNotices,
                          builder: (context, all) {
                            final notices = visibleNotices(all, widget.user);

                            if (notices.isEmpty) {
                              return _emptyPanel(
                                context,
                                context.tr('No notices yet.'),
                              );
                            }

                            return Column(
                              children: [
                                for (final notice in notices.take(3))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: NoticeCard(notice: notice),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String courseLine, bool isStudent) {
    return Container(
      decoration: const BoxDecoration(
        color: _deepGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .30,
              child: Image.asset(
                'assets/images/campus_main.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _deepGreen.withValues(alpha: .92),
                    _green.withValues(alpha: .96),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const AppLogo(size: 40),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kUniversityName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Illuminating Generations',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: _gold,
                      child: Text(
                        widget.user.initials.isEmpty
                            ? 'U'
                            : widget.user.initials,
                        style: const TextStyle(
                          color: _deepGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  context.tr('Hello, {name}', {'name': widget.user.firstName}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  courseLine.isNotEmpty
                      ? courseLine
                      : (isStudent
                            ? context.tr('Welcome back to your campus')
                            : context.tr(widget.user.role.label)),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -28,
            bottom: -48,
            child: Container(
              width: 170,
              height: 90,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String title) => Row(
    children: [
      Container(
        width: 4,
        height: 19,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 9),
      Text(
        context.tr(title),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF17231D),
        ),
      ),
    ],
  );

  Widget _shortcutGrid(BuildContext context) {
    if (widget.shortcuts.isEmpty) {
      return _emptyPanel(context, context.tr('No shortcuts available.'));
    }

    const colors = [
      Color(0xFFDDF8E9),
      Color(0xFFFFF0D2),
      Color(0xFFDCEEFF),
      Color(0xFFEDE2FF),
    ];

    const iconColors = [
      Color(0xFF087342),
      Color(0xFF9B6500),
      Color(0xFF1764B5),
      Color(0xFF7041A6),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 390 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.shortcuts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 4.2 : 2.15,
          ),
          itemBuilder: (context, index) {
            final shortcut = widget.shortcuts[index];
            final colorIndex = index % colors.length;

            return Material(
              color: colors[colorIndex],
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => shortcut.open(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .62),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          shortcut.icon,
                          color: iconColors[colorIndex],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          context.tr(shortcut.label),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFF1B2921),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: iconColors[colorIndex],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyPanel(BuildContext context, String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(message, style: const TextStyle(color: Colors.black54)),
  );
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({
    required this.next,
    required this.now,
    required this.campuses,
    required this.isLecturer,
  });

  final NextClass? next;
  final DateTime now;
  final List<Campus> campuses;
  final bool isLecturer;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF075B36);
    final n = next;

    if (n == null) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next class',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              isLecturer
                  ? context.tr('No classes are assigned to you yet.')
                  : context.tr('No classes on your timetable yet.'),
              style: const TextStyle(color: Color(0xFF34443A)),
            ),
          ],
        ),
      );
    }

    final slot = n.slot;
    final ongoing = n.isOngoingAt(now);

    final campus = campuses.where((c) => c.id == slot.campusId).firstOrNull;
    final lang = context.lang;

    final countdown = ongoing
        ? context.tr('Ends in {time}', {
            'time': formatCountdown(n.end.difference(now), lang: lang),
          })
        : context.tr('Starts in {time}', {
            'time': formatCountdown(n.untilStart(now), lang: lang),
          });

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: green, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(ongoing ? 'Happening now' : 'Next class'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  countdown,
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            slot.courseTitle,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18241D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            slot.courseCode,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _meta(
                Icons.access_time_rounded,
                context.tr('{day}, {start} to {end}', {
                  'day': dayLabel(n.start, now, lang: lang),
                  'start': formatClock(slot.startMinute),
                  'end': formatClock(slot.endMinute),
                }),
              ),
              _meta(
                Icons.location_on_outlined,
                '${slot.hallName}, ${slot.campusName}',
              ),
            ],
          ),
          const SizedBox(height: 15),

          // One clear action for both hall information and directions.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  showCampusInfo(context, slot: slot, campus: campus),
              icon: const Icon(Icons.location_on_outlined, size: 19),
              label: Text(context.tr('Hall and campus info')),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFF35644C), size: 16),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF34443A)),
        ),
      ),
    ],
  );

  static Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF163C29).withValues(alpha: .09),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}
