import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/intro/intro_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';
import '../features/listings/create_listing_screen.dart';
import '../features/listings/favorites_screen.dart';
import '../features/listings/owner_dashboard_screen.dart';
import '../features/messaging/conversations_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/property_detail/property_detail_screen.dart';
import '../features/bookings/bookings_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/analytics/owner_analytics_screen.dart';
import '../features/subscription/subscription_screen.dart';
import '../features/profile/profile_screen.dart';

/// Simple named-route table. Auth-gating for screens that require a session is
/// handled inside each screen (they redirect to /auth if needed).
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _page(const _RootGate());
      case '/home':
        return _page(const HomeScreen());
      case '/auth':
        return _page(const AuthScreen());
      case '/property':
        final id = settings.arguments as String;
        return _page(PropertyDetailScreen(propertyId: id));
      case '/create-listing':
        return _page(const CreateListingScreen());
      case '/notifications':
        return _page(const NotificationsScreen());
      case '/messages':
        return _page(const ConversationsScreen());
      case '/favorites':
        return _page(const FavoritesScreen());
      case '/owner':
        return _page(const OwnerDashboardScreen());
      case '/bookings':
        return _page(const BookingsScreen());
      case '/admin':
        return _page(const AdminScreen());
      case '/analytics':
        return _page(const OwnerAnalyticsScreen());
      case '/subscription':
        return _page(const SubscriptionScreen());
      case '/profile':
        return _page(const ProfileScreen());
      default:
        return _page(const HomeScreen());
    }
  }

  static MaterialPageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}

/// Decides the landing experience: the animated intro for logged-out visitors
/// (shown every visit until they log in), the home feed once authenticated.
/// While the initial session check runs, shows a brief branded loader.
class _RootGate extends StatelessWidget {
  const _RootGate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return auth.isLoggedIn ? const HomeScreen() : const IntroScreen();
  }
}
