import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/generated_report.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/services/analytics_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// PDF generation packages
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// Conditional import for web-specific functionality
import 'package:universal_html/html.dart' as html;

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  bool isSidebarOpen = false;
  bool _isLoading = false;

  // State for report generation
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReportType = 'Booking Summary';
  String _selectedDownloadFormat = 'CSV';
  final List<String> _reportTypes = ['Booking Summary', 'Revenue Report'];
  final List<String> _downloadFormats = ['CSV', 'PDF'];

  // State to hold the currently viewed/generated report data
  List<Map<String, dynamic>>? _reportData;
  Map<String, dynamic>? _revenueReportData;
  String _currentReportTitle = '';

  final AnalyticsService _analyticsService = AnalyticsService();
  Stream<List<GeneratedReport>>? _pastReportsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pastReportsStream == null) {
      final hotelId = Provider.of<AuthProvider>(context, listen: false).hotelId;
      if (hotelId != null) {
        setState(() {
          _pastReportsStream = _analyticsService.getPastReportsStream(hotelId);
        });
      }
    }
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

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start and end date.')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after the start date.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _reportData = null;
      _revenueReportData = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelId = authProvider.hotelId;
    final adminId = authProvider.userId;

    if (hotelId == null || adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not identify your hotel or user.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      String reportDataJson;
      if (_selectedReportType == 'Booking Summary') {
        final data = await _analyticsService.getBookingReportData(
          hotelId: hotelId,
          startDate: _startDate!,
          endDate: _endDate!,
        );
        setState(() {
          _reportData = data;
          _currentReportTitle = 'New Booking Summary Report';
        });
        reportDataJson = jsonEncode(data);
      } else {
        final data = await _analyticsService.getRevenueReportData(
          hotelId: hotelId,
          startDate: _startDate!,
          endDate: _endDate!,
        );
        setState(() {
          _revenueReportData = data;
          _currentReportTitle = 'New Revenue Report';
        });
        reportDataJson = jsonEncode(data);
      }

      final newReport = GeneratedReport(
        id: '',
        reportType: _selectedReportType,
        createdAt: DateTime.now(),
        startDate: _startDate!,
        endDate: _endDate!,
        generatedBy: adminId,
        reportDataJson: reportDataJson,
      );
      await _analyticsService.saveGeneratedReport(
        hotelId: hotelId,
        report: newReport,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated and saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _triggerDownload({GeneratedReport? pastReport}) {
    final format = _selectedDownloadFormat;
    if (format == 'CSV') {
      _downloadCsv(pastReport: pastReport);
    } else if (format == 'PDF') {
      _downloadPdf(pastReport: pastReport);
    }
  }

  Future<void> _downloadPdf({GeneratedReport? pastReport}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    final adminName = authProvider.currentAdmin != null
        ? '${authProvider.currentAdmin!.fName} ${authProvider.currentAdmin!.lName}'
        : 'Unknown Admin';
    final adminEmail = authProvider.currentAdmin != null
        ? authProvider.currentAdmin!.email
        : '';
    final hotelName = hotelProvider.hotel?.hotelName ?? 'Unknown Hotel';
    final pdf = pw.Document();
    DateTime? startDate;
    DateTime? endDate;

    if (pastReport != null) {
      startDate = pastReport.startDate;
      endDate = pastReport.endDate;
    } else {
      startDate = _startDate;
      endDate = _endDate;
    }

    String datePeriod = 'the selected period';
    if (startDate != null && endDate != null) {
      datePeriod =
          'period from: ${DateFormat('MMM dd, yyyy').format(startDate)} - To: ${DateFormat('MMM dd, yyyy').format(endDate)}';
    }

    String reportType;
    String dateStamp;
    List<Map<String, dynamic>>? bookingData;
    Map<String, dynamic>? revenueData;

    if (pastReport != null) {
      reportType = pastReport.reportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(pastReport.createdAt);
      final decodedData = jsonDecode(pastReport.reportDataJson);
      if (reportType == 'Booking Summary') {
        bookingData = (decodedData as List).cast<Map<String, dynamic>>();
      } else {
        revenueData = decodedData as Map<String, dynamic>;
      }
    } else {
      reportType = _selectedReportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      bookingData = _reportData;
      revenueData = _revenueReportData;
    }

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
                pw.Text('Hotel Name: $hotelName'),
                pw.SizedBox(height: 12),
                pw.Text(
                  reportType,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Description: A summary of ${reportType.toLowerCase()} for $datePeriod.',
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
              ],
            ),
          ];

          if (reportType == 'Booking Summary' && bookingData != null) {
            final headers = bookingData.first.keys.toList();
            final data = bookingData
                .map(
                  (row) => row.values.map((cell) => cell.toString()).toList(),
                )
                .toList();
            content.add(pw.Table.fromTextArray(headers: headers, data: data));
            num total = 0;
            for (final row in data) {
              // Safety check: Ensure row[6] exists and can be parsed
              if (row.length > 6) {
                try {
                  total += double.parse(row[6].replaceAll("\$", ''));
                } catch (e) {
                  print('Error parsing total: $e');
                }
              }
            }
            content.add(pw.SizedBox(height: 20));
            content.add(
              pw.Row(
                children: [pw.Text('Total:'), pw.Text('\$$total')],
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              ),
            );
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
          } else if (reportType == 'Revenue Report' && revenueData != null) {
            content.add(
              pw.Text(
                'Summary:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );
            content.add(pw.SizedBox(height: 10));
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
      ..download = 'report_${reportType}_$dateStamp.pdf';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  void _downloadCsv({GeneratedReport? pastReport}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    final adminName = authProvider.currentAdmin != null
        ? '${authProvider.currentAdmin!.fName} ${authProvider.currentAdmin!.lName}'
        : 'Unknown Admin';
    final adminEmail = authProvider.currentAdmin != null
        ? authProvider.currentAdmin!.email
        : '';
    final hotelName = hotelProvider.hotel?.hotelName ?? 'Unknown Hotel';

    List<Map<String, dynamic>>? dataToFormat;
    Map<String, dynamic>? revenueData;
    String reportType;
    String dateStamp;

    if (pastReport != null) {
      reportType = pastReport.reportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(pastReport.createdAt);
      final decodedData = jsonDecode(pastReport.reportDataJson);
      if (reportType == 'Booking Summary') {
        dataToFormat = (decodedData as List).cast<Map<String, dynamic>>();
      } else {
        revenueData = decodedData as Map<String, dynamic>;
      }
    } else {
      reportType = _selectedReportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      dataToFormat = _reportData;
      revenueData = _revenueReportData;
    }

    if (dataToFormat == null && revenueData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data to download.')),
      );
      return;
    }

    if (reportType == 'Revenue Report' && revenueData != null) {
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

    if (dataToFormat == null || dataToFormat.isEmpty) return;

    List<List<dynamic>> rows = [];

    rows.add(['Ministry of Tourism - Republic of Sudan']);
    rows.add(['Hotel Name:', hotelName]);
    rows.add(['Report Type:', reportType]);
    rows.add(['Generated By:', '$adminName ($adminEmail)']);
    rows.add(['Date:', dateStamp]);
    rows.add([]); // Empty row for spacing

    rows.add(dataToFormat.first.keys.toList());
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
      ..download = 'report_${reportType}_$dateStamp.csv';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  void _viewPastReport(GeneratedReport report) {
    setState(() {
      _currentReportTitle =
          'Past Report: ${report.reportType} (${DateFormat('MMM dd, yyyy').format(report.createdAt)})';
      final decodedData = jsonDecode(report.reportDataJson);
      if (report.reportType == 'Booking Summary') {
        _reportData = (decodedData as List).cast<Map<String, dynamic>>();
        _revenueReportData = null;
      } else {
        _revenueReportData = decodedData as Map<String, dynamic>;
        _reportData = null;
      }
    });
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
              HotelAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () => setState(() => isSidebarOpen = !isSidebarOpen),
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
                              onPressed: () => setState(
                                () => isSidebarOpen = !isSidebarOpen,
                              ),
                              icon: FaIcon(
                                FontAwesomeIcons.bars,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isMobile) const Header(title: "Reports & Analytics"),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildReportGenerator(),
                                  const SizedBox(height: 24),
                                  _buildPastReportsSection(),
                                  const SizedBox(height: 24),
                                  if (_isLoading)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_reportData != null)
                                    _buildBookingReportTable(
                                      _reportData!,
                                      _currentReportTitle,
                                    )
                                  else if (_revenueReportData != null)
                                    _buildRevenueReportSummary(
                                      _revenueReportData!,
                                      _currentReportTitle,
                                    ),
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
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                  ),
                                  child: const Footer(),
                                ),
                                const SizedBox(height: 10),
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
              'Past Reports',
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
                  return const Center(child: Text('No past reports found.'));
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
                            onPressed: () => _viewPastReport(report),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Download Report',
                            icon: const Icon(Icons.download),
                            onSelected: (String format) {
                              if (format == 'CSV') {
                                _downloadCsv(pastReport: report);
                              } else if (format == 'PDF') {
                                _downloadPdf(pastReport: report);
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

  Widget _buildReportGenerator() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate a New Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedReportType,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _reportTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedReportType = value;
                        _reportData = null; // Clear old data on type change
                        _revenueReportData = null;
                      });
                    }
                  },
                ),
                _buildDatePicker(
                  'Start Date',
                  _startDate,
                  () => _selectDate(context, true),
                ),
                _buildDatePicker(
                  'End Date',
                  _endDate,
                  () => _selectDate(context, false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_reportData != null || _revenueReportData != null)
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDownloadFormat,
                          dropdownColor: Colors.white,
                          items: _downloadFormats
                              .map(
                                (f) =>
                                    DropdownMenuItem(value: f, child: Text(f)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedDownloadFormat = val!),
                          decoration: const InputDecoration.collapsed(
                            hintText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _triggerDownload(),
                        icon: const Icon(Icons.download),
                        label: const Text('Download Current'),
                      ),
                    ],
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateReport,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.analytics),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Generate Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today),
      label: Text(date != null ? DateFormat('yyyy-MM-dd').format(date) : label),
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFF004d40),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }

  Widget _buildBookingReportTable(
    List<Map<String, dynamic>> data,
    String title,
  ) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text('No bookings found for the selected period.'),
          ),
        ),
      );
    }
    final columns = data.first.keys
        .map((key) => DataColumn(label: Text(key)))
        .toList();
    final rows = data.map((row) {
      return DataRow(
        cells: row.values
            .map((cell) => DataCell(Text(cell.toString())))
            .toList(),
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(columns: columns, rows: rows),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueReportSummary(Map<String, dynamic> data, String title) {
    final revenueByRoomType = data['revenueByRoomType'] as Map<String, dynamic>;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
              ),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Revenue:',
              '\$${data['totalRevenue'].toStringAsFixed(2)}',
            ),
            _buildSummaryRow('Total Bookings:', '${data['totalBookings']}'),
            _buildSummaryRow(
              'Average Booking Value:',
              '\$${data['averageBookingValue'].toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Revenue by Room Type:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...revenueByRoomType.entries.map(
              (entry) => _buildSummaryRow(
                '  - ${entry.key}:',
                '\$${entry.value.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
