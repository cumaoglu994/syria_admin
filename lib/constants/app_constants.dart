class AppConstants {
  // App Info
  static const String appName = 'Syria Heritage Admin';
  static const String appNameAr = 'لوحة إدارة التراث السوري';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String touristSitesCollection = 'tourist_sites';
  static const String eventsCollection = 'events';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String announcementsCollection = 'announcements';
  static const String contentCollection = 'content';
  static const String settingsCollection = 'settings';
  static const String personalizedRecommendationsCollection =
      'personalized_recommendations';
  static const String tripSuggestionsCollection = 'trip_suggestions';
  static const String bottomServicesCollection = 'bottom_services';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String siteImagesPath = 'site_images';
  static const String eventImagesPath = 'event_images';
  static const String announcementImagesPath = 'announcement_images';

  // Supported Languages
  static const List<String> supportedLanguages = ['ar', 'en'];
  static const String defaultLanguage = 'ar';

  // Cities in Syria
  static const List<String> syrianCities = [
    'دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'دير الزور',
    'الحسكة',
    'الرقة',
    'إدلب',
    'درعا',
    'السويداء',
    'القنيطرة',
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxTitleLength = 200;

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Cache
  static const int cacheExpirationDays = 7;

  // Notifications
  static const int maxNotificationLength = 200;

  // Maps
  static const double defaultMapZoom = 12.0;
  static const double minMapZoom = 8.0;
  static const double maxMapZoom = 18.0;

  // Colors
  static const int primaryColor = 0xFF1976D2;
  static const int secondaryColor = 0xFF424242;
  static const int accentColor = 0xFFFF5722;
  static const int successColor = 0xFF4CAF50;
  static const int warningColor = 0xFFFF9800;
  static const int errorColor = 0xFFF44336;
  static const int infoColor = 0xFF2196F3;

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // API Endpoints (if using external APIs)
  static const String baseApiUrl = 'https://api.syriaheritage.com';
  static const String weatherApiUrl = 'https://api.openweathermap.org/data/2.5';

  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'خطأ في الاتصال بالشبكة',
    'server_error': 'خطأ في الخادم',
    'unauthorized': 'غير مصرح لك بالوصول',
    'not_found': 'المحتوى غير موجود',
    'validation_error': 'بيانات غير صحيحة',
    'unknown_error': 'خطأ غير معروف',
  };

  // Success Messages
  static const Map<String, String> successMessages = {
    'created': 'تم الإنشاء بنجاح',
    'updated': 'تم التحديث بنجاح',
    'deleted': 'تم الحذف بنجاح',
    'saved': 'تم الحفظ بنجاح',
    'uploaded': 'تم الرفع بنجاح',
  };
}
