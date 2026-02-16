hotel_booking_app

Hotels Portal Reservation and Management System
Overview
Hotels Portal is a mobile and web-based application developed for the Ministry of Tourism, Antiquities and Wildlife – Sudan.
It enables guests to search, compare, and book hotels across Sudan, while providing hotel administrators and ministry officials with dashboards to manage listings, reservations, and tourism data.

This project was developed as part of the Bachelor of Science (Hons) in Information Technology graduation requirements at Future University – Sudan.


Features
👤 User Accounts: Secure registration/login for guests, hotel admins, and ministry admins.
🔍 Hotel Search & Comparison: Filter by location, price, rating, and amenities.
🏨 Hotel Profiles: Images, descriptions, rooms, reviews, and amenities.
📅 Booking Management: Real-time availability, instant booking, cancellations.
📊 Reporting:
Hotel admins: booking & revenue reports.
Ministry admins: platform-wide statistics, revenue insights, user activity.
🖥️ Dashboards:
Hotel Admin Dashboard: manage hotel info, rooms, bookings.
Ministry Admin Dashboard: approve hotels, monitor listings, generate reports.


Tech Stack
Cross-Platform Codebase: Flutter (Dart)
Mobile App: Android APK build
Web App (Admins only): Flutter Web deployed via Firebase Hosting
Backend & Database: Firebase Authentication, Firestore Database
Deployment: Firebase Hosting (admin dashboards), Android APK file (guests)


Installation & Setup
Source Code (Developers)
Clone the repository:

git clone https://github.com/yourusername/hotels-portal.git

cd hotels-portal

Ensure Flutter SDK is installed and configured.
Configure Firebase:
Create a Firebase project in the Firebase Console.
Enable Authentication and Firestore Database.
Add your Firebase config to firebase_options.dart.


Guests (Mobile App)
Download the attached APK installation file from the provided Google Drive link.
⚠️ Note: The APK file is only for Android devices.
On your Android device:
Open Settings → Security.
Enable Install from unknown sources (if prompted).
Tap the APK file to install.
Launch the app and log in/register to start booking hotels.


Admins (Web Dashboard)
Visit the web application via the provided Google Drive link to the Firebase-hosted domain.
⚠️ Note: The website requires an admin account to log in.
Login with your admin credentials:
Hotel Admins: Manage hotel profiles, rooms, bookings, and generate reports.
Ministry Admins: Approve hotels, monitor listings, oversee user activity, and generate platform-wide reports.


Usage
Guest Features
Register/login securely.
Search/filter hotels by location, price, rating, amenities.
View hotel profiles with images, rooms, reviews.
Book rooms instantly with real-time availability.
Cancel bookings and submit reviews.
Admin Features
Hotel Admins: Add/update hotel info, manage bookings, generate revenue reports.
Ministry Admins: Approve hotels, monitor activity, generate platform-wide statistics.


Limitations
No online payment integration.
No Arabic/multilingual support.
Not connected to hotel internal systems.
No transport/tour booking services.
Hotels limited to Sudan.
No iOS support (Android only).


Troubleshooting
Firebase errors: Ensure Firebase project is correctly configured and API keys are valid.
Authentication issues: Check Firebase Authentication settings.
Build errors: Run flutter clean before rebuilding.
Deployment issues: Verify Firebase CLI is installed and authenticated.


Future Enhancements
Secure online payment integration.
Arabic/multilingual support.
iOS app support.
Hotel system connectivity via APIs.
Tours & recommendations module.


Contributors
Mohammed Jamal Abdalla 
Mozan Abdelsamie Mohamed 

Supervisor: Dr. Emmalyn Capuno


License
Academic use only. Not licensed for commercial deployment.

---

