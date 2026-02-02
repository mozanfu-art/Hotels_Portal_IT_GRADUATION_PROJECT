import 'package:flutter/material.dart';
import 'package:hotel_booking_app/services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _hotelDashboardStats;

  // New state for room status
  List<Map<String, dynamic>>? _roomStatusSummary;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get hotelDashboardStats => _hotelDashboardStats;
  List<Map<String, dynamic>>? get roomStatusSummary => _roomStatusSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await _analyticsService.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHotelDashboardStats(String hotelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hotelDashboardStats = await _analyticsService.getHotelDashboardStats(
        hotelId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to fetch room status
  Future<void> fetchRoomStatusSummary(String hotelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _roomStatusSummary = await _analyticsService.getRoomStatusSummary(
        hotelId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
