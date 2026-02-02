import 'package:flutter/material.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/screens/Guest/welcome_screen.dart';
import 'package:provider/provider.dart';

class GuestSidebar extends StatelessWidget {
  const GuestSidebar({super.key});

  void _onMenuSelected(BuildContext context, String choice) async {
    switch (choice) {
      case 'Home':
        Navigator.pushNamed(context, '/home');
        break;
      case 'My Bookings':
        Navigator.pushNamed(context, '/my_bookings');
        break;
      case 'My Reviews':
        Navigator.pushNamed(context, '/my_reviews');
        break;
      case 'My Account':
        Navigator.pushNamed(context, '/my_account');
        break;
      case 'Favorites':
        Navigator.pushNamed(context, '/favorites');
        break;
      case 'Notifications':
        Navigator.pushNamed(context, '/notifications');
        break;
      case 'Settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'About Us':
        Navigator.pushNamed(context, '/about_us');
        break;
      case 'Help Center':
        Navigator.pushNamed(context, '/help_center');
        break;
      case 'Logout':
        await Provider.of<AuthProvider>(context, listen: false).signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
          (Route<dynamic> route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF004D40),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF004D40)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/hotelicon.png',
                          height: 60,
                          width: 60,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hotels Portal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home, color: Colors.white),
                  title: Text('Home', style: TextStyle(color: Colors.white)),
                  onTap: () => _onMenuSelected(context, 'Home'),
                ),
                ListTile(
                  leading: Icon(Icons.book, color: Colors.white),
                  title: Text(
                    'My Bookings',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'My Bookings'),
                ),
                ListTile(
                  leading: Icon(Icons.rate_review, color: Colors.white),
                  title: Text(
                    'My Reviews',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'My Reviews'),
                ),
                ListTile(
                  leading: Icon(Icons.account_circle, color: Colors.white),
                  title: Text(
                    'My Account',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'My Account'),
                ),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.white),
                  title: Text(
                    'Favorites',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'Favorites'),
                ),
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.white),
                  title: Text(
                    'Notifications',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'Notifications'),
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: Text(
                    'Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'Settings'),
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.white),
                  title: Text(
                    'About Us',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'About Us'),
                ),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.white),
                  title: Text(
                    'Help Center',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _onMenuSelected(context, 'Help Center'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
