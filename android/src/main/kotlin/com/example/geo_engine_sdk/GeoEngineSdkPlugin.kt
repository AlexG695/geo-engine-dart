package com.example.geo_engine_sdk

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
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

            if (cloudProjectNumber == null) {
                result.error("INVALID_ARGUMENT", "Project Number is required", null)
                return
            }

            val integrityManager = IntegrityManagerFactory.create(applicationContext)
            val nonce = java.util.UUID.randomUUID().toString()

            val request = com.google.android.play.core.integrity.IntegrityTokenRequest.builder()
                .setCloudProjectNumber(cloudProjectNumber)
                .setNonce(nonce)
                .build()

            integrityManager.requestIntegrityToken(request)
                .addOnSuccessListener { response ->
                    val integrityToken = response.token()
                    result.success(integrityToken)
                }
                .addOnFailureListener { e ->
                    result.error("INTEGRITY_ERROR", e.message, null)
                }

        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}