import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/tourist_sites_screen.dart';
import 'screens/events_screen.dart';
import 'screens/personalized_recommendations_screen.dart';
import 'screens/trip_suggestions_screen.dart';
import 'screens/bottom_services_screen.dart';
import 'screens/users_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transportation_screen.dart';
import 'screens/events_screen.dart';
import 'screens/news_screen.dart';
import 'screens/opportunities_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/accommodation_screen.dart';
import 'screens/facilities_screen.dart';
import 'screens/announcements_screen.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Localization
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
        locale: const Locale('ar', 'SA'),

        // Theme
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          // fontFamily: 'Cairo',
          useMaterial3: true,

          // App Bar Theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),

          // Card Theme
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),

          // Elevated Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

          // Text Button Theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Routes
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/sites': (context) => const TouristSitesScreen(),
          '/events': (context) => const EventsScreen(),
          '/recommendations': (context) =>
              const PersonalizedRecommendationsScreen(),
          '/trip-suggestions': (context) => const TripSuggestionsScreen(),
          '/bottom-services': (context) => const BottomServicesScreen(),
          '/users': (context) => const UsersScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/transportation': (context) => const TransportationScreen(),
          '/events': (context) => const EventsScreen(),
          '/news': (context) => const NewsScreen(),
          '/opportunities': (context) => const OpportunitiesScreen(),
          '/restaurants': (context) => const RestaurantsScreen(),
          '/accommodation': (context) => const AccommodationScreen(),
          '/facilities': (context) => const FacilitiesScreen(),
          '/announcements': (context) => const AnnouncementsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated && authProvider.canAccessAdminPanel) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
