import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/analytics_provider.dart';
import 'package:hotel_booking_app/providers/booking_provider.dart';
import 'package:hotel_booking_app/providers/guest_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/providers/search_provider.dart';
import 'package:hotel_booking_app/providers/theme_provider.dart';
import 'package:hotel_booking_app/providers/user_provider.dart';
import 'package:hotel_booking_app/screens/Guest/notifications_screen.dart';
import 'package:hotel_booking_app/utils/index.dart';
import 'package:hotel_booking_app/utils/globals.dart'; // Import globals
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

// Guest App Screens
import 'screens/Guest/welcome_screen.dart';
import 'screens/Guest/login_screen.dart';
import 'screens/Guest/signup_screen.dart';
import 'screens/Guest/home_screen.dart';
import 'screens/Guest/my_bookings_screen.dart';
import 'screens/Guest/my_reviews_screen.dart';
import 'screens/Guest/my_account_screen.dart';
import 'screens/Guest/favorites_screen.dart';
import 'screens/Guest/settings_screen.dart';
import 'screens/Guest/search_hotels_screen.dart';
import 'screens/Guest/search_results_screen.dart';
import 'screens/Guest/hotel_info_screen.dart';
import 'screens/Guest/about_us_screen.dart';
import 'screens/Guest/help_center_screen.dart';
import 'screens/Guest/select_rooms_screen.dart';
import 'screens/Guest/confirm_booking_screen.dart';
import 'screens/Guest/booking_confirmed_screen.dart';

// Admin App Screens & Wrappers
import 'screens/admins_dashboard/admin_auth_wrapper.dart';
import 'screens/admins_dashboard/auth/login_screen.dart' as admin_login;
import 'screens/admins_dashboard/hotel_admin/dashboard_screen.dart'
    as hotel_dashboard;
import 'screens/admins_dashboard/ministry_admin/ministry_dashboard_screen.dart'
    as ministry_dashboard;
import 'screens/admins_dashboard/hotel_admin/account_profile_screen.dart'
    as hotel_profile;
import 'screens/admins_dashboard/hotel_admin/hotel_admin_profile_screen.dart'
    as hotel_admin_profile;
import 'screens/admins_dashboard/hotel_admin/bookings_management_screen.dart'
    as hotel_bookings;
import 'screens/admins_dashboard/hotel_admin/guest_management_screen.dart'
    as hotel_guests;
import 'screens/admins_dashboard/hotel_admin/room_management_screen.dart'
    as hotel_rooms;
import 'screens/admins_dashboard/hotel_admin/reports_analytics_screen.dart'
    as hotel_reports;
import 'screens/admins_dashboard/hotel_admin/hotel_admin_settings_screen.dart'
    as hotel_settings;
import 'screens/admins_dashboard/hotel_admin/notifications_screen.dart'
    as hotel_notifications;
import 'screens/admins_dashboard/ministry_admin/hotel_registry_screen.dart'
    as ministry_registry;
import 'screens/admins_dashboard/ministry_admin/users_management_screen.dart'
    as ministry_users;
import 'screens/admins_dashboard/ministry_admin/reports_screen.dart'
    as ministry_reports;
import 'screens/admins_dashboard/hotel_admin/reviews_screen.dart'
    as hotel_reviews;
import 'screens/admins_dashboard/hotel_admin/booking_analytics_screen.dart'
    as hotel_booking_analytics;
import 'screens/admins_dashboard/hotel_admin/booking_details_screen.dart'
    as hotel_booking_details;
import 'screens/admins_dashboard/hotel_admin/room_details_screen.dart'
    as hotel_room_details;
import 'screens/admins_dashboard/ministry_admin/ministry_admin_profile_screen.dart'
    as ministry_admin_profile;
import 'screens/admins_dashboard/ministry_admin/custom_reports_screen.dart'
    as ministry_custom_reports;
import 'screens/admins_dashboard/ministry_admin/notifications_screen.dart'
    as ministry_notifications;
import 'screens/admins_dashboard/ministry_admin/ministry_booking_details_screen.dart'
    as ministry_booking_details;
import 'package:hotel_booking_app/screens/admins_dashboard/ministry_admin/activities_screen.dart';
import 'widgets/ai_assistant.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Android local notifications setup
  if (!kIsWeb && Platform.isAndroid) {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
    await FirebaseMessaging.instance.requestPermission(
  alert: true,
  announcement: false,
  badge: true,
  carPlay: false,
  criticalAlert: false,
  provisional: false,
  sound: true,
);

}

  if (kIsWeb) {
    // Request permission for Web notifications
    await FirebaseMessaging.instance.requestPermission();
  }

  // Handle background FCM messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground FCM messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received message: ${message.notification?.title}');
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      showNotification(
        notification.title ?? '',
        notification.body ?? '',
        flutterLocalNotificationsPlugin,
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GuestProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const AdminApp();
    } else if (!kIsWeb && Platform.isAndroid) {
      return const GuestApp();
    } else {
      return const UnsupportedScreen();
    }
  }
}

// ---------------- Guest (Mobile) Application ----------------
class GuestApp extends StatelessWidget {
  const GuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Hotels Portal',
          theme: themeProvider.currentTheme,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Stack(children: [child!, const AiAssistant()]);
          },
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/my_bookings': (context) => const MyBookingsScreen(),
            '/my_reviews': (context) => const MyReviewsScreen(),
            '/my_account': (context) => const MyAccountScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/search': (context) => const SearchHotelsScreen(),
            '/hotel_info': (context) => HotelInfoScreen(
              hotel: ModalRoute.of(context)!.settings.arguments as Hotel,
            ),
            '/search_results': (context) => SearchResultsScreen(),
            '/about_us': (context) => const AboutUsPage(),
            '/help_center': (context) => const HelpCenterScreen(),
            '/select_rooms': _buildSelectRoomsScreen,
            '/confirm_booking': (context) => const ConfirmBookingScreen(),
            '/booking_confirmed': (context) => const BookingConfirmedScreen(),
          },
        );
      },
    );
  }
}

// ---------------- Admin (Web/Windows) Application ----------------
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Hotels Portal - Admin',
          theme: themeProvider.currentTheme,
          home: const AdminAuthWrapper(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) => const admin_login.LoginScreen(),
            '/hotel-dashboard': (context) =>
                const hotel_dashboard.HotelDashboardScreen(),
            '/ministry-dashboard': (context) =>
                const ministry_dashboard.MinistryDashboardScreen(),
            '/hotel-account-profile': (context) =>
                const hotel_profile.AccountProfileScreen(),
            '/hotel-admin-profile': (context) =>
                const hotel_admin_profile.HotelAdminProfileScreen(),
            '/hotel-guest-management': (context) =>
                const hotel_guests.GuestManagementScreen(),
            '/hotel-room-management': (context) =>
                const hotel_rooms.RoomManagementScreen(),
            '/hotel-booking-analytics': (context) =>
                const hotel_booking_analytics.BookingAnalyticsScreen(),
            '/hotel-bookings-management': (context) =>
                const hotel_bookings.BookingsManagementScreen(),
            '/hotel-booking-details': (context) {
              final booking =
                  ModalRoute.of(context)!.settings.arguments as Booking;
              return hotel_booking_details.BookingDetailsScreen(
                booking: booking,
              );
            },
            '/ministry-booking-details': (context) {
              final booking =
                  ModalRoute.of(context)!.settings.arguments as Booking;
              return ministry_booking_details.MinistryBookingDetailsScreen(
                booking: booking,
              );
            },
            '/hotel-room-details': (context) {
              final room = ModalRoute.of(context)!.settings.arguments as Room;
              return hotel_room_details.RoomDetailsScreen(room: room);
            },
            '/hotel-reports-analytics': (context) =>
                const hotel_reports.ReportsAnalyticsScreen(),
            '/hotel-admin-settings': (context) =>
                const hotel_settings.HotelAdminSettingsScreen(),
            '/hotel-notifications': (context) =>
                const hotel_notifications.NotificationsScreen(),
            '/hotel-registry': (context) =>
                const ministry_registry.HotelRegistryScreen(),
            '/ministry-users': (context) =>
                const ministry_users.UsersManagementScreen(),
            '/ministry-reports': (context) =>
                const ministry_reports.ReportsScreen(),
            '/hotel-reviews': (context) => const hotel_reviews.ReviewsScreen(),
            '/ministry-admin-profile': (context) =>
                const ministry_admin_profile.MinistryAdminProfileScreen(),
            '/ministry-custom-reports': (context) =>
                const ministry_custom_reports.CustomReportsScreen(),
            '/ministry-notifications': (context) =>
                const ministry_notifications.MinistryNotificationsScreen(),
            '/ministry-activities': (context) => const ActivitiesScreen(),
          },
        );
      },
    );
  }
}

// ---------------- Auth Wrapper ----------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isLoggedIn) {
      return const HomeScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}

// ---------------- Select Rooms Helper ----------------
Widget _buildSelectRoomsScreen(BuildContext context) {
  final args =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
  final hotelJson = args['hotel'] as Map<String, dynamic>? ?? {};
  final hotel = Hotel.fromJson(hotelJson);
  final checkInDate = args['checkInDate'] as DateTime? ?? DateTime.now();
  final checkOutDate =
      args['checkOutDate'] as DateTime? ??
      DateTime.now().add(const Duration(days: 1));
  final numberOfGuests = args['numberOfGuests'] as int? ?? 1;
  return SelectRoomsScreen(
    hotel: hotel,
    initialCheckInDate: checkInDate,
    initialCheckOutDate: checkOutDate,
    initialNumberOfGuests: numberOfGuests,
  );
}

// ---------------- Unsupported Platform Screen ----------------
class UnsupportedScreen extends StatelessWidget {
  const UnsupportedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unsupported Platform')),
      body: const Center(
        child: Text(
          'Sorry, this platform is not supported.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
