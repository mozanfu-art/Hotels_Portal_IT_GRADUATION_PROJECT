import 'admin.dart';
import 'guest.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'Admin' or 'Guest'
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromAdmin(Admin admin) {
    return AppUser(
      id: admin.adminId,
      name: '${admin.fName} ${admin.lName}',
      email: admin.email,
      role: admin.role,
      isActive: admin.active,
    );
  }

  factory AppUser.fromGuest(Guest guest) {
    return AppUser(
      id: guest.guestId,
      name: '${guest.fName} ${guest.lName}',
      email: guest.email,
      role: 'Guest',
      isActive: guest.active,
    );
  }
}
