class AppConstants {
  static const bool demoPreview = bool.fromEnvironment('DEMO_PREVIEW');
  static const String appName = 'DIU Report Box';
  static const String allowedEmailDomain = 'diu.edu.bd';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabaseStorageBucket = String.fromEnvironment(
      'SUPABASE_STORAGE_BUCKET',
      defaultValue: 'app-files');

  static const int minPasswordLength = 8;
  static const int minReportDescLength = 15;
  static const int maxReportsPerDay = 5;

  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxPdfSizeBytes = 10 * 1024 * 1024; // 10 MB

  static const List<String> reportCategories = [
    'Computer/IT',
    'Electrical',
    'AC/Fan/Light',
    'Furniture',
    'Plumbing/Washroom',
    'Cleaning',
    'Other',
  ];

  static const List<String> lostFoundCategories = [
    'ID card',
    'Phone',
    'Wallet',
    'Bag',
    'Books',
    'Keys',
    'Other',
  ];

  static const List<String> resourceSubsections = [
    'previous_questions',
    'notes',
    'others',
  ];

  static const Map<String, String> resourceSubsectionLabels = {
    'previous_questions': 'Previous Questions',
    'notes': 'Notes',
    'others': 'Others',
  };
}
