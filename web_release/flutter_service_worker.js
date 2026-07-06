'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "9e934bb2241c0a19d52e2a840bf07241",
"index.html": "0daa1207a505faacaa561bd133f85a23",
"/": "0daa1207a505faacaa561bd133f85a23",
"main.dart.js": "a54f0b577d4e46b0bd7af81b357565c3",
"version.json": "7486fab03f39dd90cb2b7bbc3ac8f0b2",
"assets/assets/images/badge_level_advanced.png": "c199cb6f6c7c96c3f631b177d9edf66c",
"assets/assets/images/badge_level_beginner.png": "e588f6b7e99a4fddaa864e4de760f089",
"assets/assets/images/badge_level_intermediate.png": "cc81d805bef429248d3dba929133fb54",
"assets/assets/images/badge_level_legend.png": "97c6a859bc44e9c0a82619e3b2f60786",
"assets/assets/images/badge_level_master.png": "608fe6fc5da4ae9214c88eed5a3bf534",
"assets/assets/images/bg_desert.png": "cdf1656765bbbe4a9e32b19a68f67299",
"assets/assets/images/bg_forest.png": "da045302ef43229f67b2281e54c910fc",
"assets/assets/images/icon_accountability.png": "36342413544d512e577f7d5e49f75273",
"assets/assets/images/bg_islamic.png": "4778cbe9fc24ff37d5c6a80fad60631d",
"assets/assets/images/icon_popup_badges.png": "980d68e0034c4a094925ffe03ce20aee",
"assets/assets/images/icon_popup_certificates.png": "3aa3b14b5f4b864fe34ff08605424b20",
"assets/assets/images/icon_quran.png": "01ce1e374bc994445445cc675f4871c3",
"assets/assets/images/icon_roadmap.png": "21a037f8a4e9cb3b00f69ba2deeea7d7",
"assets/assets/images/icon_sharia.png": "1f43ac2de9beb3d4a0a846a50b72bc4c",
"assets/assets/images/icon_stories.png": "b3d53d28150c03a3163c2cca6f786616",
"assets/assets/images/icon_tips.png": "f6ac9838100b7ce07f8c44caf709dfdf",
"assets/assets/images/icon_top_badges.png": "3c4b121f122fbe255174f5d3587f7d6a",
"assets/assets/images/icon_top_leaderboard.png": "8ff686eb3ab87f9cf343fb9559f911a3",
"assets/assets/images/icon_top_notifications.png": "d61a86829ad3266df2b476f4cc02143e",
"assets/assets/images/icon_tracking.png": "15a2981cdfdbb633ab9c5a418e66b0cd",
"assets/assets/images/khatmah_bg.png": "5475383eea6e29a262b6063edc3b8309",
"assets/assets/images/khatmah_logo.jpg": "15f4642f0dd78bc589561f682aa9cfdc",
"assets/assets/images/nature_bg.png": "ae0ad5809a2236ec94fa081aff497f52",
"assets/assets/images/parchment_paper.jpg": "db544295ef2ae73bae078cfde6a5f827",
"assets/assets/images/parchment_paper_orig.jpg": "c5f04e470baa90f2007a84acdad4fef6",
"assets/assets/images/timer_bg_nature1.png": "49f4adb3e73412893b602bc7b1d9ee75",
"assets/assets/images/timer_bg_nature2.png": "95e1ea33d96ee54777038a32a06df2ba",
"assets/assets/images/timer_bg_nature3.png": "e791e4e0c2a05342d6f6522827ae9ca9",
"assets/assets/images/timer_bg_nature4.png": "18ef37a0d773e996e84ada373fc56b04",
"assets/assets/images/timer_bg_nature5.png": "d918c26953b176097893107fb3c1d385",
"assets/assets/images/timer_bg_nature6.png": "5fbb7427e0182314327314a9e2ccaacc",
"assets/assets/images/timer_bg_nature7.png": "6c4af3c28cc9a71b15e85a63bba4cee6",
"assets/assets/images/timer_bg_nature8.png": "062ccb3117ec1e1faa7dcaa3e76fd8a4",
"assets/assets/images/timer_bg_solid1.png": "756bc2560c3b546a53a20f8fdc38b765",
"assets/assets/images/timer_bg_solid2.png": "482d5bdc28c3c853dd7a5a8e68c50757",
"assets/assets/images/timer_bg_solid3.png": "cce781695fb9e878427863353cfb5bca",
"assets/assets/images/bg_mountains.png": "059b2e55bce81401fbe926804428972e",
"assets/assets/images/bg_ocean.png": "002b057dd9be9e17ca9e6e373a8e766b",
"assets/assets/images/bright_nature_bg.png": "b6910271279592d7a7e8abc77410bb73",
"assets/assets/images/graduation_cap.png": "b7f925e73f22ff78762952dc815f1e30",
"assets/assets/images/icon_breathing.png": "de99e03b82b1b477681f5d8c7fd90033",
"assets/assets/images/icon_commitment.png": "a1b30b89692b3a4248fccf77471cbe48",
"assets/assets/images/icon_community.png": "c05354a476f2a5e0518622dd3277dd4c",
"assets/assets/images/icon_dr_taafi.png": "9c45d64b1a6275785f01c1d6f182c0eb",
"assets/assets/images/icon_easy_way.png": "ba8a72c556522362cd37433db32883c7",
"assets/assets/images/icon_freedom_model.png": "42338c1f5a70e2a85d2e8c09ff25f959",
"assets/assets/images/icon_habits.png": "45948442fea55123494b86f8d2338c6c",
"assets/assets/images/icon_home.png": "2ffaff681b45f3898d741825f3b1d754",
"assets/assets/images/icon_journal.png": "8fde8507fbdaa6aaa58c04f289985ce4",
"assets/assets/images/icon_library.png": "e5f3227334e27f74720ed8c0ca5c7355",
"assets/assets/images/icon_media.png": "0b0db7d40cdd78a3d6ae266ea54e3d03",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/fonts/MaterialIcons-Regular.otf": "a02390e13f51d28c31dce637dafa290b",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "a612db3839c565c7656905fa47c8b214",
"assets/AssetManifest.bin": "2a8d11fd9dd9f274edf84ae31d125385",
"assets/AssetManifest.bin.json": "88e9e2f1d36c2c38c12d1eefd273ed91",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/NOTICES": "1660903f5026bda372da3668dab57798",
"favicon.png": "dbf513986bea603a0fa7a2e2556d381d",
"icons/Icon-192.png": "dbf513986bea603a0fa7a2e2556d381d",
"icons/Icon-512.png": "dbf513986bea603a0fa7a2e2556d381d",
"icons/Icon-maskable-192.png": "dbf513986bea603a0fa7a2e2556d381d",
"icons/Icon-maskable-512.png": "dbf513986bea603a0fa7a2e2556d381d",
"manifest.json": "66fb548e4216df3054bb0c71c5802468"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
