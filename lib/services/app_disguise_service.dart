import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppIconType {
  original,
  calculator,
  notes
}

class AppDisguiseService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('app_disguise');
  static const String _keyCurrentIcon = 'current_app_icon';
  
  AppIconType _currentIcon = AppIconType.original;

  AppIconType get currentIcon => _currentIcon;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final iconIndex = prefs.getInt(_keyCurrentIcon) ?? 0;
    _currentIcon = AppIconType.values[iconIndex];
    notifyListeners();
  }

  Future<bool> changeIcon(AppIconType newIcon) async {
    try {
      String aliasName = 'co.median.android.welxron.MainActivity';
      switch (newIcon) {
        case AppIconType.original:
          aliasName = 'co.median.android.welxron.MainActivity';
          break;
        case AppIconType.calculator:
          aliasName = 'co.median.android.welxron.CalculatorAlias';
          break;
        case AppIconType.notes:
          aliasName = 'co.median.android.welxron.NotesAlias';
          break;
      }

      final success = await _channel.invokeMethod<bool>('changeIcon', {'aliasName': aliasName});
      
      if (success == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyCurrentIcon, newIcon.index);
        _currentIcon = newIcon;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error changing app icon: $e');
      return false;
    }
  }
}
