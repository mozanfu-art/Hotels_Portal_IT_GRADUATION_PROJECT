import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:hotel_booking_app/models/generated_report.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/services/analytics_service.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import 'package:hotel_booking_app/widgets/footer.dart';

class CustomReportsScreen extends StatefulWidget {
  final GeneratedReport? pastReport;

  const CustomReportsScreen({super.key, this.pastReport});

  @override
  State<CustomReportsScreen> createState() => _CustomReportsScreenState();
}

class _CustomReportsScreenState extends State<CustomReportsScreen> {
  bool isSidebarOpen = false;
  bool _isLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedHotelId;
  String _selectedReportType = 'Platform Revenue Summary';
  String _selectedDownloadFormat = 'CSV';

  // New filters for Booking Activity Report
  String? _selectedHotelIdForBookingActivity;
  String _selectedBookingStatus = 'All';
  final List<String> _bookingStatuses = [
    'All',
    'confirmed',
    'checked_in',
    'completed',
    'cancelled',
  ];

  final List<String> _reportTypes = [
    'Platform Revenue Summary',
    'Platform Booking Activity',
    'Hotel Summary',
    'Users',
  ];
  final List<String> _downloadFormats = ['CSV', 'PDF'];
  String _selectedUserType = 'All';
  final List<String> _userTypes = [
    'All',
    'Guest',
    'Hotel Admin',
    'Ministry Admin',
  ];

  List<Hotel> _hotels = [];
  dynamic _reportData;

  final AnalyticsService _analyticsService = AnalyticsService();
  final HotelService _hotelService = HotelService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final hotelsResult = await _hotelService.getAllHotels(limit: 1000);
    setState(() {
      _hotels = hotelsResult['hotels'];
    });

    if (widget.pastReport != null) {
      _viewPastReport(widget.pastReport!);
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
    final reportsRequiringDates = [
      'Platform Revenue Summary',
      'Platform Booking Activity',
    ];
    if (reportsRequiringDates.contains(_selectedReportType) &&
        (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a start and end date for this report type.',
          ),
        ),
      );
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after the start date.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _reportData = null;
    });

    final adminId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not identify your user.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      dynamic data;
      switch (_selectedReportType) {
        case 'Platform Revenue Summary':
          data = await _analyticsService.getRevenueReportData(
            hotelId: _selectedHotelId ?? '', // Empty string for all hotels
            startDate: _startDate!,
            endDate: _endDate!,
          );
          break;
        case 'Hotel Summary':
          data = await _analyticsService.getHotelSummaryReportData();
          break;
        case 'Platform Booking Activity':
          data = await _analyticsService.getPlatformBookingActivityReportData(
            startDate: _startDate!,
            endDate: _endDate!,
            hotelId: _selectedHotelIdForBookingActivity,
            bookingStatus: _selectedBookingStatus == 'All'
                ? null
                : _selectedBookingStatus,
          );
          break;
        case 'Users':
          data = await _analyticsService.getUserDirectoryReportData(
            userType: _selectedUserType,
          );
          break;
      }

      setState(() {
        _reportData = data;
      });

      final report = GeneratedReport(
        id: '',
        reportType: _selectedReportType,
        createdAt: DateTime.now(),
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate ?? DateTime.now(),
        generatedBy: adminId,
        reportDataJson: jsonEncode(data),
      );
      await _analyticsService.saveMinistryReport(report);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated and saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, s) {
      print(s);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _triggerDownload({GeneratedReport? pastReport}) {
    if (_reportData == null && pastReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data to download.')),
      );
      return;
    }

    final format = _selectedDownloadFormat;
    if (format == 'CSV') {
      _downloadCsv(pastReport: pastReport);
    } else if (format == 'PDF') {
      _downloadPdf(pastReport: pastReport);
    }
  }

  Future<void> _downloadPdf({GeneratedReport? pastReport}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminName = authProvider.currentAdmin != null
        ? '${authProvider.currentAdmin!.fName} ${authProvider.currentAdmin!.lName}'
        : 'Unknown Admin';
    final adminEmail = authProvider.currentAdmin != null
        ? authProvider.currentAdmin!.email
        : '';

    final pdf = pw.Document();

    DateTime? startDate;
    DateTime? endDate;

    if (pastReport != null) {
      startDate = pastReport.startDate;
      endDate = pastReport.endDate;
    } else if (!['Hotel Summary', 'Users'].contains(_selectedReportType)) {
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
    dynamic dataToProcess;
    String hotelName = "Platform-Wide Report";

    if (pastReport != null) {
      reportType = pastReport.reportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(pastReport.createdAt);
      dataToProcess = jsonDecode(pastReport.reportDataJson);
    } else {
      reportType = _selectedReportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      dataToProcess = _reportData;
      if (_selectedHotelId != null) {
        for (final hotel in _hotels) {
          if (hotel.hotelId == _selectedHotelId) {
            hotelName = hotel.hotelName;
            break;
          }
        }
      }
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
                pw.Text('Report Scope: $hotelName'),
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

          if (dataToProcess is Map) {
            final revenueData = dataToProcess as Map<String, dynamic>;
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
          } else if (dataToProcess is List && dataToProcess.isNotEmpty) {
            final listData = dataToProcess.cast<Map<String, dynamic>>();
            final headers = listData.first.keys.toList();
            final data = listData
                .map(
                  (row) => row.values.map((cell) => cell.toString()).toList(),
                )
                .toList();
            content.add(pw.Table.fromTextArray(headers: headers, data: data));

            if (reportType == 'Platform Booking Activity') {
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
    final adminName = authProvider.currentAdmin != null
        ? '${authProvider.currentAdmin!.fName} ${authProvider.currentAdmin!.lName}'
        : 'Unknown Admin';
    final adminEmail = authProvider.currentAdmin != null
        ? authProvider.currentAdmin!.email
        : '';
    List<Map<String, dynamic>>? dataToFormat;
    String reportType;
    String dateStamp;
    dynamic dataToProcess;
    String hotelName = "Platform-Wide Report";

    if (pastReport != null) {
      reportType = pastReport.reportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(pastReport.createdAt);
      dataToProcess = jsonDecode(pastReport.reportDataJson);
    } else {
      reportType = _selectedReportType;
      dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      dataToProcess = _reportData;
      if (_selectedHotelId != null) {
        for (final hotel in _hotels) {
          if (hotel.hotelId == _selectedHotelId) {
            hotelName = hotel.hotelName;
            break;
          }
        }
      }
    }

    if (dataToProcess is Map) {
      final revenueData = dataToProcess as Map<String, dynamic>;
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
    } else if (dataToProcess is List) {
      dataToFormat = dataToProcess.cast<Map<String, dynamic>>();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to download.')),
      );
      return;
    }

    if (dataToFormat.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report data is empty.')));
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(['Ministry of Tourism - Republic of Sudan']);
    rows.add(['Report Scope:', hotelName]);
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
      _selectedReportType = report.reportType;
      _startDate = report.startDate;
      _endDate = report.endDate;
      _reportData = jsonDecode(report.reportDataJson);
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
              MinistryAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () => setState(() => isSidebarOpen = !isSidebarOpen),
              ),
              Expanded(
                child: Column(
                  children: [
                    MinistryAdminHeader(
                      title: 'Custom Reports',
                      showBackButton: true,
                      onBackPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  if (widget.pastReport == null)
                                    _buildReportGenerator(),
                                  const SizedBox(height: 24),
                                  if (_isLoading)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_reportData != null)
                                    _buildReportDisplay(),
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
          );
        },
      ),
    );
  }

  Widget _buildReportGenerator() {
    final reportsRequiringDates = [
      'Platform Revenue Summary',
      'Platform Booking Activity',
    ];
    final reportsRequiringHotelFilter = ['Platform Revenue Summary'];
    final reportsRequiringBookingActivityFilters = [
      'Platform Booking Activity',
    ];

    final bool showDatePickers = reportsRequiringDates.contains(
      _selectedReportType,
    );
    final bool showRevenueHotelFilter = reportsRequiringHotelFilter.contains(
      _selectedReportType,
    );
    final bool showBookingActivityFilters =
        reportsRequiringBookingActivityFilters.contains(_selectedReportType);
    final bool showUserFilter = _selectedReportType == 'Users';

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
                      });
                    }
                  },
                ),
                if (showDatePickers)
                  _buildDatePicker(
                    'Start Date',
                    _startDate,
                    () => _selectDate(context, true),
                  ),
                if (showDatePickers)
                  _buildDatePicker(
                    'End Date',
                    _endDate,
                    () => _selectDate(context, false),
                  ),
                if (showRevenueHotelFilter)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHotelId,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Hotel (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Hotels'),
                      ),
                      ..._hotels.map(
                        (hotel) => DropdownMenuItem(
                          value: hotel.hotelId,
                          child: Text(hotel.hotelName),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedHotelId = value),
                  ),
                if (showBookingActivityFilters)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHotelIdForBookingActivity,
                    hint: const Text('Filter by Hotel (Optional)'),
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Hotel',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Hotels'),
                      ),
                      ..._hotels.map(
                        (hotel) => DropdownMenuItem(
                          value: hotel.hotelId,
                          child: Text(hotel.hotelName),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _selectedHotelIdForBookingActivity = value,
                    ),
                  ),
                if (showBookingActivityFilters)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBookingStatus,
                    decoration: const InputDecoration(
                      labelText: 'Booking Status',
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: Colors.white,
                    items: _bookingStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedBookingStatus = value!),
                  ),
                if (showUserFilter)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserType,
                    decoration: const InputDecoration(
                      labelText: 'Filter by User Type',
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: Colors.white,
                    items: _userTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUserType = value;
                        });
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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

  Widget _buildReportDisplay() {
    final title = widget.pastReport != null
        ? 'Past Report: ${widget.pastReport!.reportType} (${DateFormat('MMM dd, yyyy').format(widget.pastReport!.createdAt)})'
        : 'Generated Report: $_selectedReportType';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004d40),
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDownloadFormat,
                        dropdownColor: Colors.white,
                        items: _downloadFormats
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
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
                      onPressed: () =>
                          _triggerDownload(pastReport: widget.pastReport),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            if (_reportData is Map<String, dynamic>)
              _buildRevenueReportSummary(_reportData)
            else if (_reportData is List)
              _buildGenericReportTable(_reportData)
            else
              const Text('No data available for this report type.'),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericReportTable(List<dynamic> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data found for this report.'));
    }
    final reportList = data.cast<Map<String, dynamic>>();
    final columns = reportList.first.keys
        .map((key) => DataColumn(label: Text(key)))
        .toList();
    final rows = reportList.map((row) {
      return DataRow(
        cells: row.values
            .map((cell) => DataCell(Text(cell.toString())))
            .toList(),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _buildRevenueReportSummary(Map<String, dynamic> data) {
    final revenueByRoomType = data['revenueByRoomType'] as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
