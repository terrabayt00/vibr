import 'package:flutter/material.dart';

enum DataStatus { none, waiting, contactsDone, fileDone }

class AppDataProvider with ChangeNotifier {
  DataStatus status;
  AppDataProvider({this.status = DataStatus.none});

  void updateStatus({required DataStatus newStatus}) {
    status = newStatus;
    notifyListeners();
  }
}
