import 'package:flutter/material.dart';

class SearchProvider with ChangeNotifier {
  String? _selectedState;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adults = 1;
  int _children = 0;
  int _rooms = 1;

  String? get selectedState => _selectedState;
  DateTime? get checkInDate => _checkInDate;
  DateTime? get checkOutDate => _checkOutDate;
  int get adults => _adults;
  int get children => _children;
  int get rooms => _rooms;

  void updateCriteria({
    String? state,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? rooms,
  }) {
    _selectedState = state ?? _selectedState;
    _checkInDate = checkIn ?? _checkInDate;
    _checkOutDate = checkOut ?? _checkOutDate;
    _adults = adults ?? _adults;
    _children = children ?? _children;
    _rooms = rooms ?? _rooms;
    notifyListeners();
  }

  void clear() {
    _selectedState = null;
    _checkInDate = null;
    _checkOutDate = null;
    _adults = 1;
    _children = 0;
    _rooms = 1;
    notifyListeners();
  }

  Map<String, dynamic> get searchCriteria {
    return {
      'state': _selectedState,
      'checkIn': _checkInDate,
      'checkOut': _checkOutDate,
      'adults': _adults,
      'children': _children,
      'rooms': _rooms,
    };
  }
}
