class AppRoutes {
  // Splash
  static const String splash = '/splash';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String pendingApproval = '/pending-approval';

  // Home & Bottom Nav
  static const String home = '/';
  static const String services = '/services';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Tabs
  static const String tabHome = '/home-tab';
  static const String tabOrders = '/orders-tab';
  static const String tabProfile = '/profile-tab';
  static const String tabSettings = '/settings-tab';
  static const String tabServicesManagement = '/services-management-tab';
  static const String tabAdminMigration = '/admin-migration-tab';
  static const String tabAdminUsers = '/admin-users-tab';
  static const String technicianOrders = '/technician-orders';

  // My Orders
  static const String myOrders = '/my-orders';
  static const String orderDetails = '/order-details';
  static const String editSchedule = '/edit-schedule';
  static const String editAddress = '/edit-address';

  // Sub-features (Nested routes - usually no leading slash or full path needed depending on GoRouter usage)
  static const String serviceDetails = 'details';
  static const String bookingFlow = 'booking';
  static const String editOrder = 'edit';

  // Admin
  static const String servicesManagement = '/admin';
  static const String adminSubServices = '/admin-sub-services';
  static const String adminServiceForm = '/admin-service-form';
  static const String adminSubServiceForm = '/admin-sub-service-form';
  static const String adminSubServiceDetailsEditor =
      '/admin-sub-service-details-editor';
  static const String adminServiceMigration = '/admin-service-migration';
  static const String adminServiceMigrationServices = '/admin-service-migration-services';
  static const String adminServiceMigrationSubServices = '/admin-service-migration-sub-services';
  static const String adminSliderMigration = '/admin-slider-migration';
  
  // Supabase Services View
  static const String adminSupabaseServices = '/admin-supabase-services';
  static const String adminSupabaseSubServices = '/admin-supabase-sub-services';
  static const String adminSupabaseServiceDetails = '/admin-supabase-service-details';

  // User Management (Admin)
  static const String adminUserManagement = '/admin-user-management';
  static const String adminBookings = '/admin/bookings';
}
