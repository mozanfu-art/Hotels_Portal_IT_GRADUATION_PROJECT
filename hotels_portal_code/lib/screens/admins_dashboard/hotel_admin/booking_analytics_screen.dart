import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';

class BookingAnalyticsScreen extends StatefulWidget {
  const BookingAnalyticsScreen({super.key});

  @override
  State<BookingAnalyticsScreen> createState() => _BookingAnalyticsScreenState();
}

class _BookingAnalyticsScreenState extends State<BookingAnalyticsScreen> {
  bool isSidebarOpen = false;
  String selectedFilter = 'This Month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          return Row(
            children: [
              HotelAdminSidebar(
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
                    if (isMobile)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isSidebarOpen = !isSidebarOpen;
                                });
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.bars,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isMobile) Header(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Room Status Panel
                            Text(
                              'Room Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatusCard(
                                    status: 'Available',
                                    count: 120,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatusCard(
                                    status: 'Occupied',
                                    count: 85,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatusCard(
                                    status: 'Booked',
                                    count: 45,
                                    color: Colors.yellow,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatusCard(
                                    status: 'Maintenance',
                                    count: 10,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Revenue Chart
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Revenue Analytics',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF004d40),
                                          ),
                                        ),
                                        const Spacer(),
                                        DropdownButton<String>(
                                          value: selectedFilter,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedFilter = value!;
                                            });
                                          },
                                          items:
                                              [
                                                    'This Week',
                                                    'This Month',
                                                    'This Year',
                                                  ]
                                                  .map(
                                                    (filter) =>
                                                        DropdownMenuItem(
                                                          value: filter,
                                                          child: Text(filter),
                                                        ),
                                                  )
                                                  .toList(),
                                          underline: const SizedBox(),
                                          style: TextStyle(
                                            color: const Color(0xFF004d40),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 300,
                                      child: BarChart(
                                        BarChartData(
                                          barGroups: [
                                            BarChartGroupData(
                                              x: 0,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: 5000,
                                                  color: const Color(
                                                    0xFF004d40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            BarChartGroupData(
                                              x: 1,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: 7000,
                                                  color: const Color(
                                                    0xFF004d40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            BarChartGroupData(
                                              x: 2,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: 6000,
                                                  color: const Color(
                                                    0xFF004d40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            BarChartGroupData(
                                              x: 3,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: 8000,
                                                  color: const Color(
                                                    0xFF004d40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  switch (value.toInt()) {
                                                    case 0:
                                                      return Text('Jan');
                                                    case 1:
                                                      return Text('Feb');
                                                    case 2:
                                                      return Text('Mar');
                                                    case 3:
                                                      return Text('Apr');
                                                    default:
                                                      return Text('');
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Guest Booking Table
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Guest Bookings',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF004d40),
                                          ),
                                        ),
                                        const Spacer(),
                                        SizedBox(
                                          width: 200,
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: 'Search bookings...',
                                              prefixIcon: Icon(
                                                Icons.search,
                                                color: Colors.grey,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: const Color(
                                                    0xFF004d40,
                                                  ),
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Booking ID')),
                                      DataColumn(label: Text('Guest')),
                                      DataColumn(label: Text('Room')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: [
                                      DataRow(
                                        cells: [
                                          DataCell(Text('#BK-1001')),
                                          DataCell(Text('John Doe')),
                                          DataCell(Text('Standard')),
                                          DataCell(_buildStatusChip('pending')),
                                          DataCell(
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {},
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: Text('Approve'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      DataRow(
                                        cells: [
                                          DataCell(Text('#BK-1002')),
                                          DataCell(Text('Alice Smith')),
                                          DataCell(Text('Deluxe')),
                                          DataCell(
                                            _buildStatusChip('confirmed'),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {},
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF004d40,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: Text('View'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // add more rows as needed
                                    ],
                                  ),
                                ],
                              ),
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
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'confirmed':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'pending':
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        break;
      case 'completed':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'cancelled':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final int count;
  final Color color;

  const _StatusCard({
    required this.status,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(Icons.hotel, color: color)),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
