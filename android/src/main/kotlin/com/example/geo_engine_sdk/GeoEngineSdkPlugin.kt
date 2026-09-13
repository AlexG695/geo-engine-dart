package com.example.geo_engine_sdk

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.MessageDigest
import java.util.UUID

class GeoEngineSdkPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val PREF_FILE_NAME = "geoengine_secure_prefs"
        private const val KEY_DEVICE_ID = "geoengine_device_id"
    }

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "app_device_integrity")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "generateIntegrityToken" -> {
                val cloudProjectNumber = call.argument<String>("projectNumber")?.toLongOrNull()
                val receivedNonce = call.argument<String>("nonce")

                if (cloudProjectNumber == null) {
                    result.error("INVALID_ARGUMENT", "Project Number is required", null)
                    return
                }

                val integrityManager = IntegrityManagerFactory.create(applicationContext)
                val finalNonce = receivedNonce ?: UUID.randomUUID().toString()

                val request = IntegrityTokenRequest.builder()
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
            }

            "getDeviceModel" -> {
                result.success(Build.MODEL)
            }

            "getNativeDeviceId" -> {
                try {
                    val deviceId = getOrCreateDeviceId(applicationContext)
                    result.success(deviceId)
                } catch (e: Exception) {
                    result.error("DEVICE_ID_ERROR", e.message, null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun getOrCreateDeviceId(context: Context): String {
        val prefs: SharedPreferences = try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                PREF_FILE_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback a SharedPreferences estándar si el Keystore falla
            context.getSharedPreferences(PREF_FILE_NAME, Context.MODE_PRIVATE)
        }

        val cachedId = prefs.getString(KEY_DEVICE_ID, null)
        if (!cachedId.isNullOrEmpty()) {
            return cachedId
        }

        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
        val hardwareBuild = "${Build.BOARD}:${Build.BRAND}:${Build.DEVICE}:${Build.HARDWARE}:${Build.MODEL}:${Build.PRODUCT}"

        val rawSeed = "$androidId:$hardwareBuild"
        val generatedDeviceId = hashSha256(rawSeed)

        prefs.edit().putString(KEY_DEVICE_ID, generatedDeviceId).apply()

        return generatedDeviceId
    }

    private fun hashSha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { byte -> "%02x".format(byte) }
    }
}