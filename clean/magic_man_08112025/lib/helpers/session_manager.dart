import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SessionManager {
  static const String _sessionKey = 'session_id';

  Future<int> getOrCreateSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    int? sessionId = prefs.getInt(_sessionKey);

    if (sessionId == null) {
      sessionId = Random().nextInt(90000) + 1023;
      await prefs.setInt(_sessionKey, sessionId);
      print('Новий session ID створено: $sessionId');
    } else {
      print('Існуючий session ID: $sessionId');
    }

    return sessionId;
  }

  Future<void> regenerateSessionId() async {
    final newSessionId = Random().nextInt(90000) + 1023;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, newSessionId);
    print('Session ID регенеровано: $newSessionId');
  }
}
