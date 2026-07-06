import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/app_lock_screen.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/journal_service.dart';
import 'services/habits_service.dart';
import 'services/notification_service.dart';
import 'services/tracking_service.dart';
import 'services/library_service.dart';
import 'services/accountability_service.dart';
import 'services/app_lock_service.dart';
import 'services/app_disguise_service.dart';
import 'services/partner_discovery_service.dart';
import 'widgets/welcome_message_widget.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Prevent any unhandled async errors from crashing the app (especially offline timeouts)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error Caught: ${details.exception}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Async Error Caught (Prevented Crash): $error');
      return true;
    };

    // Initialize Firebase with timeout for web
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('Firebase init timeout on web');
        throw Exception('Firebase init timeout');
      });
      
      if (!kIsWeb) {
        try {
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
          
          // Check for internet before invoking FCM Native SDKs
          bool hasInternet = false;
          try {
            final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
              hasInternet = true;
            }
          } catch (_) {}
          
          if (hasInternet) {
            FirebaseMessaging.instance.requestPermission().catchError((e) => debugPrint('FCM Perm Error: $e'));
            FirebaseMessaging.instance.subscribeToTopic('all').catchError((e) => debugPrint('FCM Topic Error: $e'));
          }
        } catch (e) {
          debugPrint('Firebase messaging setup error: $e');
        }
      }
    } catch (e) {
      debugPrint('Firebase setup error (web may continue): $e');
    }
    
    final languageService = LanguageService();
    await languageService.loadLanguage();
    
    final journalService = JournalService();
    journalService.loadEntries().catchError((e) => debugPrint('Journal Error: $e'));
    
    final habitsService = HabitsService();
    habitsService.loadHabits().catchError((e) => debugPrint('Habit Error: $e'));
    
    final trackingService = TrackingService();
    trackingService.loadRecords().catchError((e) => debugPrint('Tracking Error: $e'));
    
    final libraryService = LibraryService();
    libraryService.loadData().catchError((e) => debugPrint('Library Error: $e'));
    
    final accountabilityService = AccountabilityService();
    
    final appLockService = AppLockService();
    await appLockService.initialize();
    
    final appDisguiseService = AppDisguiseService();
    await appDisguiseService.initialize();
    
    // Initialize notifications (shows system dialog on Android 13+)
    try {
      await NotificationService().init();
      // Permission request moved to HomeScreen
    } catch (e) {
      debugPrint('Notification setup error: $e');
    }
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageService),
          ChangeNotifierProvider.value(value: journalService),
          ChangeNotifierProvider.value(value: habitsService),
          ChangeNotifierProvider.value(value: trackingService),
          ChangeNotifierProvider.value(value: libraryService),
          ChangeNotifierProvider.value(value: accountabilityService),
          ChangeNotifierProvider.value(value: appLockService),
          ChangeNotifierProvider.value(value: appDisguiseService),
          ChangeNotifierProvider(create: (_) => PartnerDiscoveryService()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('runZonedGuarded Caught Error: $error');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return MaterialApp(
          title: langService.appName,
          debugShowCheckedModeBanner: false,
          theme: AppDesign.light,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthService _authService;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if guest session exists on web
      if (kIsWeb && html.localStorage['is_guest'] == 'true') {
        debugPrint('[v0] Guest session detected on web');
        if (mounted) {
          setState(() {
            _currentUser = User.anonymous(); // Dummy user object to show as logged in
          });
        }
        return;
      }

      // Listen to auth changes but with timeout
      _authService.authStateChanges
          .timeout(const Duration(seconds: 5))
          .listen((user) {
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      }, onError: (error) {
        debugPrint('[v0] Auth error: $error');
        if (mounted) {
          setState(() {
            _currentUser = null;
          });
        }
      });

      // Also check current user immediately
      final currentUser = _authService.currentUser;
      if (mounted) {
        setState(() {
          _currentUser = currentUser;
        });
      }
    } catch (e) {
      debugPrint('[v0] Auth init error: $e');
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      return AppLockScreen(
        child: const WelcomeMessageWidget(
          child: HomeScreen(),
        ),
      );
    }

    return const LoginScreen();
  }
}

