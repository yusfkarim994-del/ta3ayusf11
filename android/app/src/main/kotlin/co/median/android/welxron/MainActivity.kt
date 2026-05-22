package co.median.android.welxron

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "app_disguise"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "changeIcon") {
                val aliasName = call.argument<String>("aliasName")
                if (aliasName != null) {
                    changeAppIcon(aliasName)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Alias name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun changeAppIcon(activeAlias: String) {
        val aliases = listOf(
            "co.median.android.welxron.MainActivity",
            "co.median.android.welxron.CalculatorAlias",
            "co.median.android.welxron.NotesAlias"
        )
        val pm = packageManager
        for (alias in aliases) {
            val state = if (alias == activeAlias) {
                 PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                 PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            pm.setComponentEnabledSetting(
                ComponentName(this, alias),
                state,
                PackageManager.DONT_KILL_APP
            )
        }
    }
}
