import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AppLockService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isAppLocked = true;
  String? _pinHash;
  
  // Getters
  bool get isLockEnabled => _isLockEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppLocked => _isAppLocked && _isLockEnabled;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;
  
  // Keys for SharedPreferences
  static const String _keyLockEnabled = 'app_lock_enabled';
  static const String _keyBiometricEnabled = 'app_lock_biometric';
  static const String _keyPinHash = 'app_lock_pin_hash';
  
  // Initialize service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLockEnabled = prefs.getBool(_keyLockEnabled) ?? false;
    _isBiometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    _pinHash = prefs.getString(_keyPinHash);
    
    // If lock is enabled, app starts locked
    _isAppLocked = _isLockEnabled;
    notifyListeners();
  }
  
  // Hash PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Set up PIN
  Future<bool> setupPin(String pin) async {
    if (pin.length < 4) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _pinHash = _hashPin(pin);
      await prefs.setString(_keyPinHash, _pinHash!);
      await prefs.setBool(_keyLockEnabled, true);
      _isLockEnabled = true;
      _isAppLocked = false; // Unlock after setup
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting up PIN: $e');
      return false;
    }
  }
  
  // Verify PIN
  bool verifyPin(String pin) {
    if (_pinHash == null) return false;
    return _hashPin(pin) == _pinHash;
  }
  
  // Unlock with PIN
  Future<bool> unlockWithPin(String pin) async {
    if (verifyPin(pin)) {
      _isAppLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric: $e');
      return false;
    }
  }
  
  // Get available biometrics
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting biometrics: $e');
      return [];
    }
  }
  
  // Enable/Disable biometric
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        // Test biometric first
        final authenticated = await authenticateWithBiometric();
        if (!authenticated) return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricEnabled, enabled);
      _isBiometricEnabled = enabled;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting biometric: $e');
      return false;
    }
  }
  
  // Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'فتح التطبيق - Unlock App',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        _isAppLocked = false;
        notifyListeners();
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }
  
  // Lock app
  void lockApp() {
    if (_isLockEnabled) {
      _isAppLocked = true;
      notifyListeners();
    }
  }
  
  // Disable lock completely
  Future<bool> disableLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLockEnabled, false);
      await prefs.setBool(_keyBiometricEnabled, false);
      await prefs.remove(_keyPinHash);
      
      _isLockEnabled = false;
      _isBiometricEnabled = false;
      _pinHash = null;
      _isAppLocked = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error disabling lock: $e');
      return false;
    }
  }
  
  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) return false;
    return setupPin(newPin);
  }
}
