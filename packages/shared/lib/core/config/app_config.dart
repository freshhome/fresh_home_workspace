class AppConfig {
  /// The Supabase Project URL, read from compile-time parameter `SUPABASE_URL`
  /// Defaults to the development database if not specified.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dsddwqdixsdhaspfafuy.supabase.co',
  );

  /// The Supabase Public Anonymous Key, read from compile-time parameter `SUPABASE_ANON_KEY`
  /// Defaults to the development anon key if not specified.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_vNlyMzHSX84GUhL-JWXqLA_S7shZml_',
  );

  /// The active environment descriptor, read from compile-time parameter `ENVIRONMENT`
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
}
