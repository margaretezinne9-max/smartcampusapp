import 'campus_models.dart';

class DemoStudent {
  const DemoStudent(this.id, this.name);
  final String id;
  final String name;
}

class DemoDataset {
  const DemoDataset({
    required this.campuses,
    required this.slots,
    required this.notices,
    required this.enrollments,
    required this.exams,
    required this.resources,
  });

  final List<Campus> campuses;
  final List<ClassSlot> slots;
  final List<Notice> notices;
  final List<Enrollment> enrollments;
  final List<Exam> exams;
  final List<CourseResource> resources;
}

/// Sample data for demos and evaluation. Replace the campus names, links and
/// directions with the real ones from Hill City University.
abstract final class DemoData {
  static const department = 'Computer Science';
  static const level = 400;
  static const mainCampusId = 'main';
  static const annexCampusId = 'annex';

  static DemoDataset build({
    required String lecturerId,
    required String lecturerName,
    required List<DemoStudent> students,
    required DateTime now,
  }) {
    const campuses = [
      Campus(
        id: mainCampusId,
        name: 'Main Campus',
        address: 'Hill City University, Main Campus',
        mapsUrl: 'https://www.google.com/maps/search/?api=1&query=Hill+City+University',
        directions:
            'Enter through the main gate and follow the central road to the '
            'lecture theatres.',
      ),
      Campus(
        id: annexCampusId,
        name: 'Annex Campus',
        address: 'Hill City University, Annex Campus',
        mapsUrl: 'https://www.google.com/maps/search/?api=1&query=Hill+City+University+Annex',
        directions:
            'Take the shuttle from the main gate (about 10 minutes). The ICT '
            'labs and seminar rooms are on the first floor.',
      ),
    ];

    ClassSlot slot(
      String code,
      String title,
      int weekday,
      int startHour,
      int endHour,
      String hall,
      Campus campus,
    ) => ClassSlot(
      id: 'slot-${code.replaceAll(' ', '').toLowerCase()}',
      courseCode: code,
      courseTitle: title,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      department: department,
      level: level,
      weekday: weekday,
      startMinute: startHour * 60,
      endMinute: endHour * 60,
      hallName: hall,
      campusId: campus.id,
      campusName: campus.name,
    );

    final slots = [
      slot(
        'CSC 401',
        'Compiler Construction',
        DateTime.monday,
        8,
        10,
        'Lecture Theatre 2',
        campuses[0],
      ),
      slot(
        'CSC 403',
        'Artificial Intelligence',
        DateTime.tuesday,
        10,
        12,
        'Lecture Theatre 1',
        campuses[0],
      ),
      slot(
        'CSC 405',
        'Computer Networks',
        DateTime.wednesday,
        12,
        14,
        'ICT Lab 3',
        campuses[1],
      ),
      slot(
        'CSC 499',
        'Final Year Project Defence',
        DateTime.thursday,
        14,
        16,
        'Seminar Room A',
        campuses[1],
      ),
      slot(
        'GST 401',
        'Entrepreneurship Studies',
        DateTime.friday,
        9,
        11,
        'Lecture Theatre 3',
        campuses[0],
      ),
    ];

    final enrollments = [
      for (final student in students)
        for (final s in slots)
          Enrollment(
            id: '${student.id}_${s.courseCode.replaceAll(' ', '')}',
            studentId: student.id,
            studentName: student.name,
            courseCode: s.courseCode,
            courseTitle: s.courseTitle,
            lecturerId: lecturerId,
            units: s.courseCode == 'CSC 499'
                ? 6
                : s.courseCode == 'GST 401'
                ? 2
                : 3,
          ),
    ];

    final notices = [
      Notice(
        id: 'demo-welcome',
        title: 'Welcome to the new semester',
        body:
            'Check your timetable for the hall and campus of every class. '
            'Lectures start on Monday.',
        category: NoticeCategory.notice,
        createdAt: now,
        authorName: 'Admin',
      ),
      Notice(
        id: 'demo-cultural-day',
        title: 'Cultural Day',
        body: 'Come in your traditional attire. Venue: Main Campus field.',
        category: NoticeCategory.event,
        createdAt: now.subtract(const Duration(days: 1)),
        eventDate: now.add(const Duration(days: 14)),
        authorName: 'Admin',
      ),
      Notice(
        id: 'demo-tests',
        title: 'First-semester tests',
        body:
            'The test timetable will be pinned on each department notice '
            'board.',
        category: NoticeCategory.event,
        createdAt: now.subtract(const Duration(days: 2)),
        eventDate: now.add(const Duration(days: 21)),
        authorName: 'Admin',
      ),
      Notice(
        id: 'demo-defence',
        title: 'Project defence day',
        body: 'Final-year students must submit their projects one week before.',
        category: NoticeCategory.event,
        createdAt: now.subtract(const Duration(days: 3)),
        eventDate: now.add(const Duration(days: 35)),
        authorName: 'Admin',
      ),
      Notice(
        id: 'demo-mr-miss',
        title: 'Mr and Miss Hill City',
        body: 'Auditions hold at the Main Campus hall.',
        category: NoticeCategory.event,
        createdAt: now.subtract(const Duration(days: 4)),
        eventDate: now.add(const Duration(days: 28)),
        authorName: 'Admin',
      ),
      Notice(
        id: 'demo-exams',
        title: 'Exams begin',
        body: 'Check your department notice board for the exam timetable.',
        category: NoticeCategory.event,
        createdAt: now.subtract(const Duration(days: 5)),
        eventDate: now.add(const Duration(days: 42)),
        authorName: 'Admin',
      ),
      Notice(
        id: 'demo-convocation',
        title: 'Convocation',
        body: 'Graduating students must confirm their gowns.',
        category: NoticeCategory.event,
        createdAt: now.subtract(const Duration(days: 6)),
        eventDate: now.add(const Duration(days: 60)),
        authorName: 'Admin',
      ),
      // Targeted notices: only the matching department and level see them.
      Notice(
        id: 'demo-project-briefing',
        title: 'Final-year project briefing',
        body:
            'All Computer Science level 400 students meet the project '
            'coordinator.',
        category: NoticeCategory.notice,
        createdAt: now.subtract(const Duration(hours: 3)),
        authorName: 'Admin',
        department: department,
        level: level,
      ),
      Notice(
        id: 'demo-law-orientation',
        title: 'Law orientation week',
        body: 'New Law students: orientation starts on Monday.',
        category: NoticeCategory.notice,
        createdAt: now.subtract(const Duration(hours: 5)),
        authorName: 'Admin',
        department: 'Law',
        level: 100,
      ),
    ];

    // One exam per course, a few days apart, starting three weeks from now.
    final exams = [
      for (var i = 0; i < slots.length; i++)
        Exam(
          id: 'exam-${slots[i].courseCode.replaceAll(' ', '').toLowerCase()}',
          courseCode: slots[i].courseCode,
          courseTitle: slots[i].courseTitle,
          lecturerId: lecturerId,
          department: department,
          level: level,
          start: DateTime(now.year, now.month, now.day + 21 + i * 3, 9),
          durationMinutes: slots[i].courseCode == 'GST 401' ? 90 : 120,
          hallName: slots[i].hallName,
          campusId: slots[i].campusId,
          campusName: slots[i].campusName,
        ),
    ];

    CourseResource resource(
      int slotIndex,
      String id,
      String title,
      ResourceType type,
      int daysAgo,
    ) => CourseResource(
      id: id,
      courseCode: slots[slotIndex].courseCode,
      courseTitle: slots[slotIndex].courseTitle,
      title: title,
      // Placeholder links: replace with real ones when lecturers share them.
      url:
          'https://example.com/${slots[slotIndex].courseCode.replaceAll(' ', '').toLowerCase()}/$id',
      type: type,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      department: department,
      level: level,
      createdAt: now.subtract(Duration(days: daysAgo)),
    );

    final resources = [
      resource(
        0,
        'res-csc401-notes',
        'Lecture notes: Lexical analysis',
        ResourceType.notes,
        5,
      ),
      resource(
        0,
        'res-csc401-pq',
        'Past questions 2024/2025',
        ResourceType.pastQuestions,
        4,
      ),
      resource(
        1,
        'res-csc403-notes',
        'Search algorithms slides',
        ResourceType.notes,
        3,
      ),
      resource(
        2,
        'res-csc405-guide',
        'Wireshark practical guide',
        ResourceType.other,
        2,
      ),
    ];

    return DemoDataset(
      campuses: campuses,
      slots: slots,
      notices: notices,
      enrollments: enrollments,
      exams: exams,
      resources: resources,
    );
  }
}
