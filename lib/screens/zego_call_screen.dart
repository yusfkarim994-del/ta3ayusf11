import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Add async for Timer
import '../services/language_service.dart';
import '../services/call_room_service.dart';

// Conditional imports for web
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'package:recovery_app/utils/ui_web_wrapper.dart' as ui_web;
import 'package:url_launcher/url_launcher.dart';

// Mobile specific imports for InAppWebView
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class ZegoCallScreen extends StatefulWidget {
  final String roomName;
  final String displayName;
  final String odaID;
  final bool isVideoCall;
  final String roomType; // 'community', 'group'
  final String groupId;

  const ZegoCallScreen({
    super.key,
    required this.roomName,
    required this.displayName,
    required this.odaID,
    this.isVideoCall = true,
    this.roomType = 'community',
    this.groupId = '',
  });

  @override
  State<ZegoCallScreen> createState() => _ZegoCallScreenState();
}

class _ZegoCallScreenState extends State<ZegoCallScreen> {
  bool _isLoading = true;
  bool _isWebView = false; // Detect if running inside a WebView
  late String _viewId;
  late String _zegoUrl;
  final CallRoomService _callRoomService = CallRoomService();
  String? _roomId;
  Timer? _heartbeatTimer;
  InAppWebViewController? _webViewController;

  // ZEGOCLOUD credentials - Get these from https://console.zegocloud.com/
  // Free tier includes 10,000 minutes per month
  static const int appID = 0; // TODO: Replace with your AppID from ZEGOCLOUD console
  static const String serverSecret = ''; // TODO: Replace with your ServerSecret

  @override
  void initState() {
    super.initState();
    _viewId = 'zego-call-${DateTime.now().millisecondsSinceEpoch}';
    
    // Use odaID directly if it's already a sanitized room ID (joining existing room)
    // Otherwise sanitize it (creating new room)
    final roomId = widget.odaID.startsWith('laabrah_') 
        ? widget.odaID 
        : _sanitizeRoomName(widget.odaID);
    _roomId = roomId;
    final userName = Uri.encodeComponent(widget.displayName);
    
    // Get Firebase UID for consistent user identity across sessions
    final userId = FirebaseAuth.instance.currentUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Using ZEGOCLOUD's prebuilt solution via web component
    // This URL pattern works with their web demo/prebuilt UI
    _zegoUrl = 'https://zegocloud.github.io/zego_uikit_prebuilt_web/video_conference/index.html?roomID=$roomId&userID=$userId&userName=$userName';
    
    if (kIsWeb) {
      // Check if running inside a WebView (APK wrapper)
      _checkIfWebView();
      
      // Only register Zego view if not in WebView
      if (!_isWebView) {
        _registerZegoView();
      } else {
        // Auto-open in external browser if in WebView
        Future.delayed(Duration.zero, () {
           html.window.open(_zegoUrl, '_blank');
        });
      }
    } else {
      // Mobile platforms - request permissions first, then load InAppWebView
      _requestPermissionsAndLoad();
    }
    
    // Join the call room in Firebase
    _joinCallRoom();
    
    // Start heartbeat timer
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_roomId != null) {
        _callRoomService.sendHeartbeat(_roomId!);
      }
    });
  }

  /// Request camera and microphone permissions before loading the call
  Future<void> _requestPermissionsAndLoad() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('Microphone permission: $micStatus');
      
      // Request camera permission if video call
      if (widget.isVideoCall) {
        final camStatus = await Permission.camera.request();
        debugPrint('Camera permission: $camStatus');
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    
    // Load the webview regardless of permission result
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkIfWebView() {
    if (kIsWeb) {
      try {
        final userAgent = html.window.navigator.userAgent.toLowerCase();
        // Detect Android WebView or iOS WebView
        _isWebView = userAgent.contains('wv') || // Android WebView
                     userAgent.contains('webview') ||
                     (userAgent.contains('android') && userAgent.contains('version/')) ||
                     userAgent.contains('fbav') || // Facebook In-App Browser
                     userAgent.contains('instagram'); // Instagram In-App Browser
        
        if (_isWebView) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error checking WebView: $e');
      }
    }
  }

  Future<void> _joinCallRoom() async {
    try {
      await _callRoomService.createOrJoinRoom(
        roomName: widget.roomName,
        roomId: _roomId!,
        isVideoCall: widget.isVideoCall,
        groupId: widget.groupId,
        roomType: widget.roomType,
      );
    } catch (e) {
      debugPrint('Error joining call room: $e');
    }
  }

  Future<void> _leaveCallRoom() async {
    try {
      if (_roomId != null) {
        await _callRoomService.leaveRoom(_roomId!);
      }
    } catch (e) {
      debugPrint('Error leaving call room: $e');
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _leaveCallRoom();
    super.dispose();
  }

  String _sanitizeRoomName(String name) {
    // Remove special characters and spaces, keep alphanumeric and underscores
    return 'laabrah_${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}';
  }

  void _registerZegoView() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = _zegoUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'camera; microphone; fullscreen; display-capture; autoplay; clipboard-write'
          ..allowFullscreen = true;
        
        iframe.onLoad.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
        
        return iframe;
      },
    );
    
    // Set loading to false after a timeout as backup
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                lang.isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isVideoCall 
                        ? [const Color(0xFF4facfe), const Color(0xFF00f2fe)]
                        : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isVideoCall ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: lang.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getCallTypeText(lang),
                      style: lang.getTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Powered by ZEGOCLOUD badge
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, color: Colors.blue, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'ZEGO',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Back to Main Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      lang.isRTL ? Icons.arrow_forward : Icons.arrow_back,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang.currentLanguage == AppLanguage.arabic 
                          ? 'العودة للرئيسية' 
                          : lang.currentLanguage == AppLanguage.kurdish 
                              ? 'گەڕانەوە بۆ سەرەکی' 
                              : 'Back to Main',
                      style: lang.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
            // ZEGOCLOUD content
            _buildCallBody(),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isVideoCall 
                                ? [const Color(0xFF4facfe), const Color(0xFF00f2fe)]
                                : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isVideoCall ? Icons.videocam : Icons.call,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getConnectingText(lang),
                        style: lang.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.roomName,
                        style: lang.getTextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ZEGOCLOUD branding
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud, color: Colors.blue, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Powered by ZEGOCLOUD',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCallBody() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    // Show message if running inside a WebView (APK wrapper)
    if (kIsWeb && _isWebView) {
      return _buildWebViewMessage(lang);
    }
    
    if (kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    } else {
      // For mobile platforms - use InAppWebView to load ZEGOCLOUD directly in app
      return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_zegoUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          supportMultipleWindows: true,
          transparentBackground: true,
          useHybridComposition: true,
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          // Allow inline media playback
          allowsInlineMediaPlayback: true,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var uri = navigationAction.request.url;
          if (uri != null && uri.scheme != "http" && uri.scheme != "https" && uri.scheme != "about" && uri.scheme != "data" && uri.scheme != "blob") {
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
        onPermissionRequest: (controller, request) async {
          // Grant all requested permissions (camera, microphone, etc.)
          final resources = <PermissionResourceType>[];
          
          for (final resource in request.resources) {
            if (resource == PermissionResourceType.MICROPHONE) {
              final status = await Permission.microphone.request();
              if (status.isGranted) {
                resources.add(PermissionResourceType.MICROPHONE);
              }
            } else if (resource == PermissionResourceType.CAMERA) {
              final status = await Permission.camera.request();
              if (status.isGranted) {
                resources.add(PermissionResourceType.CAMERA);
              }
            } else {
              // Grant other permissions by default
              resources.add(resource);
            }
          }
          
          if (resources.isNotEmpty) {
            return PermissionResponse(
              resources: resources,
              action: PermissionResponseAction.GRANT,
            );
          }
          
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.DENY,
          );
        },
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStart: (controller, url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onLoadStop: (controller, url) async {
          if (mounted) setState(() => _isLoading = false);
        },
        onCreateWindow: (controller, createWindowAction) async {
          // Handle popup windows from ZEGOCLOUD
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                insetPadding: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.grey[200],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: InAppWebView(
                          windowId: createWindowAction.windowId,
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            useShouldOverrideUrlLoading: true,
                            mediaPlaybackRequiresUserGesture: false,
                          ),
                          onPermissionRequest: (controller, request) async {
                            return PermissionResponse(
                              resources: request.resources,
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                          onCloseWindow: (controller) {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          return true;
        },
        onReceivedError: (controller, request, error) {
          debugPrint('Zego WebView error: ${error.description}');
        },
      );
    }
  }

  Widget _buildWebViewMessage(LanguageService lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isVideoCall 
                      ? [const Color(0xFF4facfe), const Color(0xFF00f2fe)]
                      : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isVideoCall ? Icons.videocam : Icons.call,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              lang.currentLanguage == AppLanguage.arabic 
                  ? 'المكالمات في التطبيق'
                  : lang.currentLanguage == AppLanguage.kurdish 
                      ? 'پەیوەندی لە ناو ئەپ'
                      : 'Calls in App',
              style: lang.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              lang.currentLanguage == AppLanguage.arabic 
                  ? 'اضغط الزر أدناه لفتح المكالمة\nفي متصفح خارجي'
                  : lang.currentLanguage == AppLanguage.kurdish 
                      ? 'کلیکی لەسەر دوگمەی خوارەوە بکە\nبۆ کردنەوەی کۆڵ لە براوزەر'
                      : 'Tap the button below to open\nthe call in an external browser',
              style: lang.getTextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Open in Browser Button
            GestureDetector(
              onTap: () async {
                if (kIsWeb) {
                  html.window.open(_zegoUrl, '_blank');
                } else {
                  final uri = Uri.parse(_zegoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4facfe).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      lang.currentLanguage == AppLanguage.arabic 
                          ? 'فتح المكالمة في المتصفح'
                          : lang.currentLanguage == AppLanguage.kurdish 
                              ? 'کردنەوەی کۆڵ لە براوزەر'
                              : 'Open Call in Browser',
                      style: lang.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Room info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    lang.currentLanguage == AppLanguage.arabic 
                        ? 'غرفة:'
                        : lang.currentLanguage == AppLanguage.kurdish 
                            ? 'ژوور:'
                            : 'Room:',
                    style: lang.getTextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    widget.roomName,
                    style: lang.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Localization helpers
  String _getCallTypeText(LanguageService lang) {
    if (widget.isVideoCall) {
      switch (lang.currentLanguage) {
        case AppLanguage.arabic: return 'مكالمة فيديو';
        case AppLanguage.kurdish: return 'پەیوەندی ڤیدیۆیی';
        case AppLanguage.english: return 'Video Call';
      }
    } else {
      switch (lang.currentLanguage) {
        case AppLanguage.arabic: return 'مكالمة صوتية';
        case AppLanguage.kurdish: return 'پەیوەندی دەنگی';
        case AppLanguage.english: return 'Voice Call';
      }
    }
  }

  String _getConnectingText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'جاري الاتصال...';
      case AppLanguage.kurdish: return 'پەیوەستدەبێت...';
      case AppLanguage.english: return 'Connecting...';
    }
  }
}
