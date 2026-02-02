import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/app_user.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/user_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking_app/widgets/footer.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  bool isSidebarOpen = false;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  final bool _sortAscending = true;
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'Guest', 'Hotel Admin', 'Ministry Admin'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchAllUsers();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: Row(
        children: [
          MinistryAdminSidebar(
            isMobile: isMobile,
            isOpen: isSidebarOpen,
            onToggle: () {
              setState(() {
                isSidebarOpen = !isSidebarOpen;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                const MinistryAdminHeader(title: 'Users Management'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Consumer2<UserProvider, AuthProvider>(
                          builder: (context, userProvider, authProvider, child) {
                            if (userProvider.isLoading) {
                              return const _UserTablePlaceholder();
                            }
                            if (userProvider.error != null) {
                              return Center(
                                child: Text('Error: ${userProvider.error}'),
                              );
                            }

                            // Exclude the current user from the list
                            final currentUserId = authProvider.user?.uid;
                            final currentUserName =
                                '${authProvider.currentAdmin?.fName} ${authProvider.currentAdmin?.lName}';
                            final allUsers = userProvider.users
                                .where((user) => user.id != currentUserId)
                                .toList();

                            // Apply search and role filters
                            final filteredUsers = allUsers.where((user) {
                              final roleMatch =
                                  _selectedRole == 'All' ||
                                  (_selectedRole == 'Guest' &&
                                      user.role == 'Guest') ||
                                  (_selectedRole == 'Hotel Admin' &&
                                      user.role == 'hotel admin') ||
                                  (_selectedRole == 'Ministry Admin' &&
                                      user.role == 'ministry admin');

                              final searchMatch =
                                  _searchQuery.isEmpty ||
                                  user.name.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  ) ||
                                  user.email.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  );

                              return roleMatch && searchMatch;
                            }).toList();

                            final userDataSource = UserDataTableSource(
                              users: filteredUsers,
                              onStatusToggle: (user) {
                                userProvider.toggleUserStatus(
                                  user,
                                  currentUserId!,
                                  currentUserName,
                                );
                              },
                            );

                            return SizedBox(
                              width: double.infinity,
                              child: PaginatedDataTable(
                                header: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Search by name or email',
                                            prefixIcon: Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          dropdownColor: Colors.white,
                                          initialValue: _selectedRole,
                                          decoration: InputDecoration(
                                            labelText: 'Filter by Role',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          items: _roles.map((String role) {
                                            return DropdownMenuItem<String>(
                                              value: role,
                                              child: Text(role),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            setState(() {
                                              _selectedRole = newValue!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Role')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                source: userDataSource,
                                rowsPerPage: _rowsPerPage,
                                onRowsPerPageChanged: (value) {
                                  setState(() {
                                    _rowsPerPage = value!;
                                  });
                                },
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Footer(),
                      ],
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

class UserDataTableSource extends DataTableSource {
  final List<AppUser> users;
  final ValueChanged<AppUser> onStatusToggle;

  UserDataTableSource({required this.users, required this.onStatusToggle});

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) {
      return null;
    }
    final user = users[index];
    return DataRow(
      cells: [
        DataCell(Text(user.name)),
        DataCell(Text(user.email)),
        DataCell(Text(user.role)),
        DataCell(_buildStatusChip(user.isActive)),
        DataCell(
          Switch(
            value: user.isActive,
            onChanged: (value) {
              onStatusToggle(user);
            },
            activeThumbColor: Colors.green,
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;

  static Widget _buildStatusChip(bool isActive) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _UserTablePlaceholder extends StatelessWidget {
  const _UserTablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for the search bar
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder for table rows
            ...List.generate(11, (index) => const _PlaceholderRow()),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderRow extends StatefulWidget {
  const _PlaceholderRow();

  @override
  State<_PlaceholderRow> createState() => _PlaceholderRowState();
}

class _PlaceholderRowState extends State<_PlaceholderRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 52, // Approx height of a DataRow
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildPlaceholderBox(120), // Name
            const SizedBox(width: 24),
            _buildPlaceholderBox(180), // Email
            const SizedBox(width: 24),
            _buildPlaceholderBox(80), // Role
            const SizedBox(width: 24),
            _buildPlaceholderBox(80), // Status
            const SizedBox(width: 24),
            _buildPlaceholderBox(80), // Approval
            const Spacer(),
            _buildPlaceholderBox(50), // Actions
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox(double width) {
    return Container(
      height: 20,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
