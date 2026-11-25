package br.dev.yago.climapp_cc20262

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "br.dev.yago.climapp/device"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceCountry" -> {
                        val country = getDeviceCountry()
                        if (country != null) {
                            result.success(country)
                        } else {
                            result.error(
                                "COUNTRY_UNAVAILABLE",
                                "Não foi possível identificar o país do dispositivo.",
                                null
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getDeviceCountry(): String? {
        val telephonyManager =
            getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager

        val simCountry = telephonyManager?.simCountryIso
        if (!simCountry.isNullOrBlank()) {
            return simCountry.uppercase(Locale.ROOT)
        }

        val networkCountry = telephonyManager?.networkCountryIso
        if (!networkCountry.isNullOrBlank()) {
            return networkCountry.uppercase(Locale.ROOT)
        }

        val localeCountry = Locale.getDefault().country
        return if (localeCountry.isNotBlank()) {
            localeCountry.uppercase(Locale.ROOT)
        } else {
            null
        }
    }
}
