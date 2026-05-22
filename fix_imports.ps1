Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content) {
        $newContent = $content -replace "import 'dart:html'", "import 'package:universal_html/html.dart'"
        $newContent = $newContent -replace "import 'dart:ui_web' as ui_web;", "import 'package:recovery_app/utils/ui_web_wrapper.dart' as ui_web;"
        $newContent = $newContent -replace "import 'dart:js_util'", "import 'package:universal_html/js_util.dart'"
        if ($content -ne $newContent) {
            Write-Host "Updated $($_.FullName)"
            Set-Content -Path $_.FullName -Value $newContent
        }
    }
}
