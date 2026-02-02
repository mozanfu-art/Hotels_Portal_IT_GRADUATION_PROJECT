import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double descriptionFontSize;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.descriptionFontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF0C3B2E)),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0C3B2E),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: descriptionFontSize,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      drawer: GuestSidebar(),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 120,
            color: Color(0xFF004D40),
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: Color(0xFFFFFFFF)),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Help Center',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Scrollable main content
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Help Center',
                                style: TextStyle(
                                  color: Color(0xFF004D40),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'How can we help you today?',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search for help...',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Color(0xFF004D40),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            InfoCard(
                              icon: Icons.menu_book_outlined,
                              title: 'Getting Started',
                              description:
                                  "Learn how to create an account, search for hotels, and make your first booking.",
                              descriptionFontSize: 13.0,
                            ),
                            InfoCard(
                              icon: Icons.person_outline,
                              title: 'Account Management',
                              description:
                                  "Find out how to manage your profile, view bookings, and change settings.",
                              descriptionFontSize: 13.0,
                            ),
                            InfoCard(
                              icon: Icons.support_agent_outlined,
                              title: 'Support',
                              description:
                                  "Contact our support team if you can't find the answer to your question.",
                              descriptionFontSize: 15.0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxWidth: 600),
                            padding: EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Frequently Asked Questions',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ExpansionTile(
                                  title: Text(
                                    'How do I create an account?',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Click the Sign Up button on the homepage and fill out the registration form with your details.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ExpansionTile(
                                  title: Text(
                                    'How can I book a hotel?',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        '''Once you're logged in, you can search for hotels in various cities, select desired dates and room type, and then proceed to confirm your booking. No payment is required until you arrive at the hotel.''',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ExpansionTile(
                                  title: Text(
                                    'Can I cancel my booking?',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Yes, you can cancel your booking through your account dashboard. Please check the hotel\'s specific cancellation policy for any potential fees.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ExpansionTile(
                                  title: Text(
                                    'How do I change my password?',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'You can change your password from the Settings tab in your account profile page.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      Spacer(),
                      SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: const Footer(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
