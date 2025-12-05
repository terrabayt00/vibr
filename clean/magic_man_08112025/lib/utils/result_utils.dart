import 'package:shared_preferences/shared_preferences.dart';

class ResultUtils {
  Future<SharedPreferences> _getInstans() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  setLoadState(String key, bool value) async {
    final prefs = await _getInstans();
    await prefs.setBool(key, value);
  }

  Future<bool> getLoadState(String key) async {
    bool state = false;
    final prefs = await _getInstans();
    final bool? result = prefs.getBool(key);
    if (result != null) {
      state = result;
    }
    return state;
  }
}
