package com.example.expressive_shade

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class ExpressiveApplication : FlutterApplication() {
    companion object {
        const val CACHED_ENGINE_ID = "expressive_shade_engine"
        var sharedEngine: FlutterEngine? = null
            private set
    }

    override fun onCreate() {
        super.onCreate()
        try {
            val engine = FlutterEngine(this)
            engine.navigationChannel.setInitialRoute("/overlay?target=quick_settings")
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            FlutterEngineCache.getInstance().put(CACHED_ENGINE_ID, engine)
            ExpressiveNativeBridge.init(this)
            ExpressiveNativeBridge.registerChannels(this, engine)
            sharedEngine = engine
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
