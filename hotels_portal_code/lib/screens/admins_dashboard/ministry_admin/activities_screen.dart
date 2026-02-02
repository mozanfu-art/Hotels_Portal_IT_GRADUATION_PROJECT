import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/services/activity_service.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  bool isSidebarOpen = false;
  final ActivityService _activityService = ActivityService();
  List<Activity> _activities = [];
  bool _isLoading = false;

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedActivityType;
  final List<String> _activityTypes = [
    'All Types',
    'New User Registration',
    'New Hotel Registration',
    'User Status Update',
    'New Booking',
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities({bool clearFilters = false}) async {
    setState(() {
      _isLoading = true;
      if (clearFilters) {
        _startDate = null;
        _endDate = null;
        _selectedActivityType = null;
      }
    });

    final activities = await _activityService.getAllActivities(
      filterByType: _selectedActivityType == 'All Types'
          ? null
          : _selectedActivityType,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() {
      _activities = activities;
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: Row(
        children: [
          MinistryAdminSidebar(
            isMobile: MediaQuery.of(context).size.width < 768,
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
                const MinistryAdminHeader(title: "System Activities"),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'System Activity Log',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF004d40),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildFilterSection(),
                              const SizedBox(height: 24),
                              _isLoading
                                  ? _buildPlaceholders()
                                  : _activities.isEmpty
                                  ? _buildEmptyState()
                                  : _buildActivityList(),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                10,
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : 'Start Date',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _endDate != null
                        ? DateFormat('yyyy-MM-dd').format(_endDate!)
                        : 'End Date',
                  ),
                ),
                DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: _selectedActivityType,
                  hint: const Text('Filter by Type'),
                  items: _activityTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityType = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _loadActivities(clearFilters: true),
                  child: const Text('Clear Filters'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _loadActivities(),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(activity.type),
            subtitle: Text(activity.description),
            trailing: Text(
              DateFormat(
                'yyyy-MM-dd – kk:mm',
              ).format(activity.timestamp.toDate()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholders() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => const _PlaceholderRow(),
    );
  }

  Widget _buildEmptyState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No activities found for the selected filters.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderRow extends StatefulWidget {
  const _PlaceholderRow();

  @override
  State<_PlaceholderRow> createState() => __PlaceholderRowState();
}

class __PlaceholderRowState extends State<_PlaceholderRow>
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey.shade300),
          title: Container(height: 16, width: 150, color: Colors.grey.shade300),
          subtitle: Container(
            height: 14,
            width: 250,
            color: Colors.grey.shade300,
          ),
          trailing: Container(
            height: 14,
            width: 100,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
