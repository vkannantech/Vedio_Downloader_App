package com.kannantech.clivon

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kannantech.clivon/ytdl"
    private val EVENTS = "com.kannantech.clivon/events"
    
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Method Channel for Commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            YoutubeDL.getInstance().init(applicationContext)
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("INIT_ERROR", e.message, null) }
                        }
                    }
                }
                "fetchMetadata" -> {
                    val url = call.argument<String>("url")!!
                    val cookiesPath = call.argument<String>("cookiesPath")
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val request = YoutubeDLRequest(url)
                            if (cookiesPath != null) request.addOption("--cookies", cookiesPath)
                            
                            // SPEED OPTIMIZATION FLAGS
                            request.addOption("--skip-download")
                            request.addOption("--no-playlist") 
                            request.addOption("--flat-playlist")
                            request.addOption("--dump-single-json")
                            request.addOption("--no-warnings")
                            
                            val info = YoutubeDL.getInstance().getInfo(request)
                            val mapper = com.fasterxml.jackson.databind.ObjectMapper()
                            mapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
                            val json = mapper.writeValueAsString(info)
                            runOnUiThread { result.success(json) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("METADATA_ERROR", e.message, null) }
                        }
                    }
                }
                "download" -> {
                    val id = call.argument<String>("id")!!
                    val url = call.argument<String>("url")!!
                    val savePath = call.argument<String>("savePath")!!
                    val audioOnly = call.argument<Boolean>("audioOnly") ?: false
                    val formatId = call.argument<String?>("formatId")
                    val cookiesPath = call.argument<String>("cookiesPath")
                    
                    startDownload(id, url, savePath, audioOnly, formatId, cookiesPath)
                    result.success(null) 
                }
                "cancel" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        try {
                            YoutubeDL.getInstance().destroyProcessById(id)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Event Channel for Progress Updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun startDownload(id: String, url: String, savePath: String, audioOnly: Boolean, formatId: String?, cookiesPath: String?) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val request = YoutubeDLRequest(url)
                request.addOption("-o", "$savePath/%(title)s.%(ext)s")
                request.addOption("--no-mtime") 
                
                if (cookiesPath != null) {
                    request.addOption("--cookies", cookiesPath)
                }

                if (formatId != null) {
                    request.addOption("-f", formatId)
                }

                if (audioOnly) {
                    request.addOption("-x") // Extract audio
                    request.addOption("--audio-format", "mp3")
                }
                
                // Execute with callback
                YoutubeDL.getInstance().execute(request, id) { progress: Float, eta: Long, line: String? ->
                    // Send progress event to Flutter
                    val event = mapOf(
                        "id" to id,
                        "progress" to progress,
                        "eta" to eta,
                        "line" to (line ?: ""),
                        "status" to "downloading"
                    )
                    runOnUiThread {
                        eventSink?.success(event)
                    }
                }

                // Completion Event
                val successEvent = mapOf(
                    "id" to id,
                    "progress" to 100.0,
                    "status" to "completed"
                )
                runOnUiThread {
                    eventSink?.success(successEvent)
                }

            } catch (e: Exception) {
                if (e.message?.contains("canceled") == true) {
                     val cancelEvent = mapOf(
                        "id" to id,
                        "status" to "canceled"
                    )
                     runOnUiThread { eventSink?.success(cancelEvent) }
                } else {
                    val errorEvent = mapOf(
                        "id" to id,
                        "status" to "failed",
                        "error" to (e.message ?: "Unknown Error")
                    )
                    runOnUiThread { eventSink?.success(errorEvent) }
                }
                e.printStackTrace()
            }
        }
    }
}
