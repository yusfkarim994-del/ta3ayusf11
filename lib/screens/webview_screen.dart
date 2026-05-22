import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/language_service.dart';

// Conditional imports
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'package:recovery_app/utils/ui_web_wrapper.dart' as ui_web;

// Mobile specific import for InAppWebView popup handling
// Mobile specific import for InAppWebView popup handling
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  bool _isLoading = true;
  late String _viewId;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _viewId = 'webview-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      _registerWebView();
    } else {
      // Ensure loading spinner dissipates natively anyway
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _isLoading) setState(() => _isLoading = false);
      });
    }
  }

  void _registerWebView() {
    // Register iframe for web platform
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; camera; microphone'
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
    Future.delayed(const Duration(seconds: 3), () {
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
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0a1628) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              lang.isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.title,
            style: lang.getTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF4facfe) : const Color(0xFF00BCD4),
                    ),
                  ),
                )
              : null,
        ),
        body: SafeArea(
          bottom: true,
          top: false, // AppBar handles the top area
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    } else {
      // Use flutter_inappwebview for Mobile (Android/iOS)
      // This fully supports proper popup window flows for Auth (e.g. puter.com)
      // and Telegram live streams with camera/microphone access
      return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          supportMultipleWindows: true,
          transparentBackground: false,
          useHybridComposition: true,
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          clearCache: false,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var uri = navigationAction.request.url;
          if (uri != null && uri.scheme != "http" && uri.scheme != "https" && uri.scheme != "about" && uri.scheme != "data" && uri.scheme != "blob" && uri.scheme != "javascript") {
            // If the scheme is unknown (like tg: or whatsapp:), try to launch it externally
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
        onPermissionRequest: (controller, request) async {
          // Handle permission requests from web pages (e.g., Telegram live streams)
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
              // Grant other permissions (e.g., media) by default
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
          
          // Inject script to hide Lovable and Manus badges/branding
          await controller.evaluateJavascript(source: """
            (function() {
              var style = document.createElement('style');
              style.innerHTML = '#lovable-badge, .lovable-badge, [class*="lovable"], [id*="lovable"], button[aria-label*="Lovable"], a[href*="lovable.app"], div[style*="z-index: 2147483647"], div[style*="z-index: 9999999"], [data-lovable], [class*="manus"], [id*="manus"], a[href*="manus.app"], a[href*="manus.space"], button[aria-label*="Manus"], [data-manus] { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }';
              document.head.appendChild(style);
              
              var removeBadges = function() {
                // Remove by attributes - Lovable & Manus
                var elements = document.querySelectorAll('[class*="lovable"], [id*="lovable"], a[href*="lovable.app"], button[aria-label*="Lovable"], [data-lovable], [class*="manus"], [id*="manus"], a[href*="manus.app"], a[href*="manus.space"], button[aria-label*="Manus"], [data-manus]');
                elements.forEach(function(el) { el.style.setProperty('display', 'none', 'important'); });
                
                // Remove by text content
                var walk = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT, null, false);
                var node;
                while(node = walk.nextNode()) {
                  if (node.innerText && (node.innerText.includes('Lovable') || node.innerText.includes('Manus') || node.innerText.includes('manus'))) {
                    var s = window.getComputedStyle(node);
                    if (s.position === 'fixed' || s.position === 'absolute') {
                      node.style.setProperty('display', 'none', 'important');
                    }
                  }
                  // Hide fixed/absolute elements with high z-index often used for badges
                  var style = window.getComputedStyle(node);
                  if ((style.position === 'fixed' || style.position === 'absolute') && parseInt(style.zIndex) > 1000) {
                     if (node.innerText && (node.innerText.includes('Edit') || node.innerText.includes('Lovable') || node.innerText.includes('Manus') || node.innerText.includes('Built with'))) {
                       node.style.setProperty('display', 'none', 'important');
                     }
                  }
                }
              };
              removeBadges();
              setInterval(removeBadges, 1000);
            })();
          """);

          // Inject script to hide telegram search button if user is on telegram
          if (url != null && (url.toString().contains('telegram.org') || url.toString().contains('t.me'))) {
            await controller.evaluateJavascript(source: """
              var style = document.createElement('style');
              style.innerHTML = '.input-search, .search-input, .SearchInput, .chatlist-top .search, .header-search, .Header-search, button[title="Search"], div[title="Search"], .tgico-search, .input-wrapper input[placeholder="Search"], #search-input { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; width: 0 !important; height: 0 !important; position: absolute !important; }';
              document.head.appendChild(style);
              
              // Continuously enforce in case Telegram re-renders dynamically
              setInterval(function() {
                var searchBtn = document.querySelectorAll('.input-search, .search-input, .SearchInput, .chatlist-top .search, .header-search, .Header-search, button[title="Search"], div[title="Search"], .tgico-search, #search-input');
                searchBtn.forEach(function(el) { el.style.display = 'none'; });
              }, 1000);
            """);
          }
        },
        onCreateWindow: (controller, createWindowAction) async {
          // When the site opens a popup (like Puter.com login), show it in a dialog!
          // This simulates "opening in browser" but keeps it perfectly linked to the app and session.
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
                      // Header with close button
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
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            var uri = navigationAction.request.url;
                            if (uri != null && uri.scheme != "http" && uri.scheme != "https" && uri.scheme != "about" && uri.scheme != "data" && uri.scheme != "blob") {
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                          onPermissionRequest: (controller, request) async {
                            // Also grant permissions in popup windows
                            return PermissionResponse(
                              resources: request.resources,
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                          onCloseWindow: (controller) {
                            // Automatically dismiss the popup when puter.com finishes auth and calls window.close()
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
          return true; // Indicate that we handled the new window request
        },
      );
    }
  }
}
