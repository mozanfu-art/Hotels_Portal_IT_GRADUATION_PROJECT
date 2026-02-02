import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/generated_report.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/ministry_admin/custom_reports_screen.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/services/admin_service.dart';
import 'package:hotel_booking_app/services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import 'package:hotel_booking_app/widgets/footer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isSidebarOpen = false;
  final AnalyticsService _analyticsService = AnalyticsService();
  Stream<List<GeneratedReport>>? _pastReportsStream;

  @override
  void initState() {
    super.initState();
    _pastReportsStream = _analyticsService.getPastMinistryReportsStream();
  }

  void _navigateToCustomReports() {
    Navigator.pushNamed(context, '/ministry-custom-reports');
  }

  Future<void> _downloadPdf(GeneratedReport pastReport) async {
    final pdf = pw.Document();
    final dateStamp = DateFormat('yyyy-MM-dd').format(pastReport.createdAt);
    final decodedData = jsonDecode(pastReport.reportDataJson);
    final admin = await AdminService().getAdmin(pastReport.generatedBy);
    final adminName = admin != null
        ? '${admin.fName} ${admin.lName}'
        : 'Unknown Admin';
    final adminEmail = admin != null ? admin.email : '';
    DateTime? startDate = pastReport.startDate;
    DateTime? endDate = pastReport.endDate;
    String datePeriod = 'the selected period';
    if (!['Hotel Summary', 'Users'].contains(pastReport.reportType)) {
      datePeriod =
          'period from: ${DateFormat('MMM dd, yyyy').format(startDate)} - To: ${DateFormat('MMM dd, yyyy').format(endDate)}';
    }
    String hotelName = "Platform-Wide Report";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          List<pw.Widget> content = [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Ministry of Tourism - Republic of Sudan',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Report Scope: $hotelName'),
                pw.SizedBox(height: 12),
                pw.Text(
                  pastReport.reportType,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Description: A summary of ${pastReport.reportType.toLowerCase()} for $datePeriod.',
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
              ],
            ),
          ];

          if (decodedData is List && decodedData.isNotEmpty) {
            final listData = decodedData.cast<Map<String, dynamic>>();
            final headers = listData.first.keys.toList();
            final data = listData
                .map(
                  (row) => row.values.map((cell) => cell.toString()).toList(),
                )
                .toList();
            content.add(pw.Table.fromTextArray(headers: headers, data: data));
            if (pastReport.reportType == 'Platform Booking Activity') {
              num total = 0;
              for (final row in data) {
                total += double.parse(row[5].replaceAll("\$", ''));
              }
              content.add(pw.SizedBox(height: 20));
              content.add(
                pw.Row(
                  children: [pw.Text('Total:'), pw.Text('\$$total')],
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                ),
              );
            }

            content.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(thickness: 2),
                  pw.Text('Prepared by: $adminName on $dateStamp'),
                  pw.Text('Email: $adminEmail'),
                ],
              ),
            );
          } else if (decodedData is Map) {
            final revenueData = decodedData.cast<String, dynamic>();
            content.add(
              pw.Text(
                'Summary:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );
            content.add(pw.SizedBox(height: 10));
            revenueData.forEach((key, value) {
              if (key != 'revenueByRoomType' ||
                  key != 'startDate' ||
                  key != 'endDate') {}
            });
            content.add(
              pw.Text("Total Revenue: \$${revenueData['totalRevenue']}"),
            );

            content.add(
              pw.Text("Total Bookings: ${revenueData['totalBookings']}"),
            );
            content.add(
              pw.Text(
                "Average Booking Value: \$${revenueData['averageBookingValue']}",
              ),
            );
            content.add(pw.SizedBox(height: 20));
            content.add(
              pw.Text(
                'Revenue by Room Type:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );
            (revenueData['revenueByRoomType'] as Map<String, dynamic>).forEach((
              key,
              value,
            ) {
              content.add(
                pw.Text('$key: \$${(value as double).toStringAsFixed(2)}'),
              );
            });

            content.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(thickness: 2),
                  pw.Text('Prepared by: $adminName on $dateStamp'),
                  pw.Text('Email: $adminEmail'),
                ],
              ),
            );
          } else {
            content.add(pw.Text('No data available for this report.'));
          }

          return content;
        },
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'report_${pastReport.reportType}_$dateStamp.pdf';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  void _downloadCsv(GeneratedReport pastReport) {
    List<Map<String, dynamic>>? dataToFormat;
    final decodedData = jsonDecode(pastReport.reportDataJson);
    final dateStamp = DateFormat('yyyy-MM-dd').format(pastReport.createdAt);

    if (decodedData is List) {
      dataToFormat = decodedData.cast<Map<String, dynamic>>();
    } else if (decodedData is Map) {
      final revenueData = decodedData.cast<String, dynamic>();
      dataToFormat = [
        {'Metric': 'Start Date', 'Value': revenueData['startDate']},
        {'Metric': 'End Date', 'Value': revenueData['endDate']},
        {
          'Metric': 'Total Revenue',
          'Value': '\$${revenueData['totalRevenue'].toStringAsFixed(2)}',
        },
        {
          'Metric': 'Total Bookings',
          'Value': revenueData['totalBookings'].toString(),
        },
        {
          'Metric': 'Average Booking Value',
          'Value': '\$${revenueData['averageBookingValue'].toStringAsFixed(2)}',
        },
        {'Metric': '', 'Value': ''},
        {'Metric': 'Revenue by Room Type', 'Value': ''},
        ...(revenueData['revenueByRoomType'] as Map<String, dynamic>).entries
            .map(
              (entry) => {
                'Metric': entry.key,
                'Value': '\$${entry.value.toStringAsFixed(2)}',
              },
            ),
      ];
    }

    if (dataToFormat == null || dataToFormat.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report data is empty.')));
      return;
    }

    List<List<dynamic>> rows = [dataToFormat.first.keys.toList()];
    for (var map in dataToFormat) {
      rows.add(map.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'report_${pastReport.reportType}_$dateStamp.csv';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          return Row(
            children: [
              MinistryAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () => setState(() => isSidebarOpen = !isSidebarOpen),
              ),
              Expanded(
                child: Column(
                  children: [
                    const MinistryAdminHeader(title: 'Reports & Analytics'),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reports Dashboard',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCustomReports,
                                  icon: const Icon(Icons.add),
                                  label: const Text('New Custom Report'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildPastReportsSection(),
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

  Widget _buildPastReportsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently Generated Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<GeneratedReport>>(
              stream: _pastReportsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading past reports.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No past reports found.'),
                    ),
                  );
                }
                final reports = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.description,
                        color: Color(0xFF004d40),
                      ),
                      title: Text(report.reportType),
                      subtitle: Text(
                        'Generated on: ${DateFormat.yMMMd().format(report.createdAt)}\n'
                        'Period: ${DateFormat.yMMMd().format(report.startDate)} - ${DateFormat.yMMMd().format(report.endDate)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View',
                            onPressed: () {
                              // Re-use custom report screen to view past data
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomReportsScreen(pastReport: report),
                                ),
                              );
                            },
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Download Report',
                            icon: const Icon(Icons.download),
                            onSelected: (String format) {
                              if (format == 'CSV') {
                                _downloadCsv(report);
                              } else if (format == 'PDF') {
                                _downloadPdf(report);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'CSV',
                                    child: ListTile(
                                      leading: Icon(FontAwesomeIcons.fileCsv),
                                      title: Text('Download as CSV'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'PDF',
                                    child: ListTile(
                                      leading: Icon(FontAwesomeIcons.filePdf),
                                      title: Text('Download as PDF'),
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
