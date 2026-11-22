import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/department_model.dart';
import '../core/models/lost_found_model.dart';
import '../core/models/qa_post_model.dart';
import '../core/models/report_model.dart';
import '../core/models/resource_model.dart';
import '../core/models/user_model.dart';
import 'demo_mode.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/lost_found/presentation/lost_found_providers.dart';
import '../features/qa/presentation/qa_providers.dart';
import '../features/reports/presentation/report_providers.dart';
import '../features/resources/presentation/resource_providers.dart';

final _demoUser = UserModel(
  uid: 'demo-student',
  name: 'Demo Student',
  email: 'demo@diu.edu.bd',
  departmentId: 'cse',
  studentId: '221-15-000',
  createdAt: DateTime(2026, 1, 1),
);

final _demoLostFoundItems = [
  LostFoundModel(
    id: 'demo-lost-id',
    type: 'lost',
    title: 'Lost student ID card',
    description: 'I may have dropped my ID card near the library entrance.',
    category: 'ID card',
    location: 'Central Library',
    date: DateTime(2026, 11, 14),
    contact: 'demo@diu.edu.bd',
    authorUid: 'student-1',
    authorName: 'Nusrat Jahan',
  ),
  LostFoundModel(
    id: 'demo-found-keys',
    type: 'found',
    title: 'Keys found near the cafeteria',
    description: 'A set of keys was found beside the main cafeteria.',
    category: 'Keys',
    location: 'Main Cafeteria',
    date: DateTime(2026, 11, 12),
    authorUid: 'student-2',
    authorName: 'Mahin Ahmed',
  ),
  LostFoundModel(
    id: 'demo-resolved-wallet',
    type: 'lost',
    title: 'Wallet returned to its owner',
    description: 'A brown wallet was found and returned to the owner.',
    category: 'Wallet',
    location: 'Academic Building',
    date: DateTime(2026, 11, 10),
    status: 'resolved',
    authorUid: 'student-3',
    authorName: 'Rafi Hasan',
  ),
];

final _demoQaPosts = [
  QaPostModel(
    id: 'demo-qa-registration',
    title: 'How do I register for a retake?',
    body:
        'Could someone explain the retake registration process and the deadline?',
    authorUid: 'student-4',
    authorName: 'Ayesha Rahman',
    likeCount: 8,
    commentCount: 2,
    createdAt: DateTime(2026, 11, 15),
  ),
  QaPostModel(
    id: 'demo-qa-library',
    title: 'Library hours during exam week',
    body:
        'Does the central library stay open later during the final exam period?',
    isAnonymous: true,
    likeCount: 4,
    commentCount: 1,
    createdAt: DateTime(2026, 11, 13),
  ),
];

final _demoDepartments = [
  const DepartmentModel(
      id: 'cse', name: 'Computer Science & Engineering', code: 'CSE'),
  const DepartmentModel(
      id: 'eee', name: 'Electrical & Electronic Engineering', code: 'EEE'),
];

final _demoRooms = [
  const RoomModel(
      id: 'cse-401',
      roomNo: '401',
      building: 'Daffodil Smart City',
      floor: '4th Floor'),
  const RoomModel(
      id: 'cse-402',
      roomNo: '402',
      building: 'Daffodil Smart City',
      floor: '4th Floor'),
];

final _demoReports = [
  ReportModel(
    id: 'demo-report-1042',
    refNo: 'R-1042',
    reporterUid: _demoUser.uid,
    reporterName: _demoUser.name,
    departmentId: 'cse',
    roomId: 'cse-401',
    roomNo: '401',
    category: 'Computer/IT',
    description:
        'The projector in the lab is not displaying the instructor computer.',
    status: 'in_progress',
    smsStatus: 'sent',
    createdAt: DateTime(2026, 11, 14),
  ),
  ReportModel(
    id: 'demo-report-1038',
    refNo: 'R-1038',
    reporterUid: _demoUser.uid,
    reporterName: _demoUser.name,
    departmentId: 'eee',
    roomId: 'eee-201',
    roomNo: '201',
    category: 'Electrical',
    description: 'One row of lights in the lecture room is not working.',
    status: 'resolved',
    smsStatus: 'sent',
    createdAt: DateTime(2026, 11, 8),
  ),
];

final _demoResources = [
  ResourceModel(
    id: 'demo-resource-previous',
    subsection: 'previous_questions',
    title: 'Data Structures Midterm Questions',
    departmentId: 'cse',
    courseCode: 'CSE221',
    courseTitle: 'Algorithms',
    term: 'Fall 2025',
    description: 'A sample set of previous midterm questions for revision.',
    attachments: const [
      ResourceAttachment(
          kind: 'pdf', url: '', name: 'CSE221-midterm.pdf', sizeBytes: 1200000),
    ],
    uploaderUid: 'student-5',
    uploaderName: 'Tanvir Islam',
    createdAt: DateTime(2026, 10, 20),
  ),
  ResourceModel(
    id: 'demo-resource-notes',
    subsection: 'notes',
    title: 'Database Normalization Notes',
    departmentId: 'cse',
    courseCode: 'CSE311',
    courseTitle: 'Database Systems',
    term: 'Spring 2026',
    description: 'A concise guide to 1NF, 2NF, 3NF and BCNF.',
    attachments: const [
      ResourceAttachment(
          kind: 'link', url: 'https://example.com', name: 'Study guide'),
    ],
    uploaderUid: 'student-6',
    uploaderName: 'Samia Akter',
    createdAt: DateTime(2026, 10, 18),
  ),
  ResourceModel(
    id: 'demo-resource-others',
    subsection: 'others',
    title: 'Academic Calendar',
    departmentId: 'cse',
    courseCode: 'CSE',
    courseTitle: 'Department Notices',
    term: 'Fall 2026',
    description: 'A sample academic calendar resource.',
    attachments: const [
      ResourceAttachment(
          kind: 'link', url: 'https://example.com', name: 'Calendar'),
    ],
    uploaderUid: 'student-7',
    uploaderName: 'Student Affairs',
    createdAt: DateTime(2026, 10, 16),
  ),
];

final List<Override> demoPreviewOverrides = [
  demoModeProvider.overrideWithValue(true),
  currentUserProfileProvider.overrideWith((ref) => Stream.value(_demoUser)),
  lostFoundFeedProvider.overrideWith((ref) {
    final filters = ref.watch(lostFoundFilterProvider);
    final query = filters.searchQuery.toLowerCase();
    return Stream.value(_demoLostFoundItems.where((item) {
      final typeMatches = filters.typeFilter == 'all' ||
          (filters.typeFilter == 'resolved'
              ? item.isResolved
              : item.type == filters.typeFilter && !item.isResolved);
      final categoryMatches = filters.categoryFilter == 'all' ||
          item.category == filters.categoryFilter;
      final queryMatches = query.isEmpty ||
          '${item.title} ${item.description} ${item.location}'
              .toLowerCase()
              .contains(query);
      return typeMatches && categoryMatches && queryMatches;
    }).toList());
  }),
  qaFeedProvider.overrideWith((ref) {
    final filters = ref.watch(qaFilterProvider);
    final query = filters.searchQuery.toLowerCase();
    final posts = _demoQaPosts.where((post) {
      return query.isEmpty ||
          '${post.title} ${post.body}'.toLowerCase().contains(query);
    }).toList();
    if (filters.sortBy == 'active') {
      posts.sort((a, b) => b.commentCount.compareTo(a.commentCount));
    }
    return Stream.value(posts);
  }),
  qaCommentsProvider.overrideWith((ref, postId) {
    return Stream.value([
      const CommentModel(
        id: 'demo-comment-1',
        text:
            'Check the student portal under the exam section; the retake form is there.',
        authorName: 'Nusrat',
        createdAt: null,
      ),
    ]);
  }),
  isLikedProvider.overrideWith((ref, postId) => Stream.value(false)),
  departmentsProvider.overrideWith((ref) => Stream.value(_demoDepartments)),
  roomsForDepartmentProvider.overrideWith((ref, departmentId) {
    return Stream.value(
        departmentId == 'cse' ? _demoRooms : const <RoomModel>[]);
  }),
  myReportsProvider.overrideWith((ref) => Stream.value(_demoReports)),
  reportNotesProvider.overrideWith((ref, reportId) {
    return Stream.value([
      const ReportNoteModel(
        id: 'demo-note-1',
        byUid: 'maintenance',
        byName: 'Maintenance Team',
        text: 'A technician has been assigned to check the reported issue.',
        newStatus: 'in_progress',
      ),
    ]);
  }),
  resourcesBySubsectionProvider.overrideWith((ref, subsection) {
    final filters = ref.watch(resourceFilterProvider);
    final query =
        '${filters.courseCode} ${filters.searchQuery}'.toLowerCase().trim();
    return Stream.value(_demoResources.where((resource) {
      final subsectionMatches = resource.subsection == subsection;
      final departmentMatches = filters.departmentId == 'all' ||
          resource.departmentId == filters.departmentId;
      final queryMatches = query.isEmpty ||
          '${resource.courseCode} ${resource.courseTitle} ${resource.title}'
              .toLowerCase()
              .contains(query);
      return subsectionMatches && departmentMatches && queryMatches;
    }).toList());
  }),
];
