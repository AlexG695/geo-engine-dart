package com.example.geo_engine_sdk

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.os.Build
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import android.content.Context

class GeoEngineSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel

    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "app_device_integrity")
        channel.setMethodCallHandler(this)

        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "generateIntegrityToken") {
            val cloudProjectNumber = call.argument<String>("projectNumber")?.toLongOrNull()
            val receivedNonce = call.argument<String>("nonce")

            if (cloudProjectNumber == null) {
                result.error("INVALID_ARGUMENT", "Project Number is required", null)
                return
            }

            val integrityManager = IntegrityManagerFactory.create(applicationContext)
            val finalNonce = receivedNonce ?: java.util.UUID.randomUUID().toString()

            val request = com.google.android.play.core.integrity.IntegrityTokenRequest.builder()
                .setCloudProjectNumber(cloudProjectNumber)
                .setNonce(finalNonce)
                .build()

            integrityManager.requestIntegrityToken(request)
                .addOnSuccessListener { response ->
                    val integrityToken = response.token()
                    result.success(integrityToken)
                }
                .addOnFailureListener { e ->
                    result.error("INTEGRITY_ERROR", e.message, null)
                }

        } else if (call.method == "getDeviceModel") {
            result.success(Build.MODEL)

        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun getOrCreateDeviceId(context: Context): String {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        val securePrefs = EncryptedSharedPreferences.create(
            context,
            PREF_FILE_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SKEY,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )

        val cachedId = securePrefs.getString(KEY_DEVICE_ID, null)
        if (!cachedId.isNullOrEmpty()) {
            return cachedId
        }

        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
        val hardwareBuild = "${Build.BOARD}:${Build.BRAND}:${Build.DEVICE}:${Build.HARDWARE}:${Build.MODEL}:${Build.PRODUCT}"

        val rawSeed = "$androidId:$hardwareBuild"
        val generatedDeviceId = hashSha256(rawSeed)

        securePrefs.edit().putString(KEY_DEVICE_ID, generatedDeviceId).apply()

        return generatedDeviceId
    }

    private fun hashSha256(input: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }
}