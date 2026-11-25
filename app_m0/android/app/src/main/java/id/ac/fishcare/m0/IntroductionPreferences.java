package id.ac.fishcare.m0;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/** A UI preference, independent of all farming databases and migrations. */
final class IntroductionPreferences {
    private IntroductionPreferences() {}

    static void register(Activity activity, FlutterEngine engine) {
        final Context app = activity.getApplicationContext();
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "fishcare/introduction")
            .setMethodCallHandler((call, result) -> {
                if (!call.method.equals("completed") && !call.method.equals("complete")) {
                    result.notImplemented();
                    return;
                }
                // Disk access is kept off the Android UI thread.
                new Thread(() -> {
                    try {
                        SharedPreferences prefs = app.getSharedPreferences("fishcare_introduction", Context.MODE_PRIVATE);
                        boolean value = call.method.equals("completed")
                            ? prefs.getBoolean("completed_v1", false)
                            : prefs.edit().putBoolean("completed_v1", true).commit();
                        activity.runOnUiThread(() -> result.success(value));
                    } catch (RuntimeException error) {
                        activity.runOnUiThread(() -> result.error("preference_failed", "Preferensi perkenalan belum dapat disimpan/dibaca.", null));
                    }
                }, "fishcare-introduction").start();
            });
    }
}
