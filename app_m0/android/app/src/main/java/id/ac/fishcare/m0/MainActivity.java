package id.ac.fishcare.m0;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.Manifest;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Build;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.Handler;
import android.os.Looper;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private final ReportExport reportExport = new ReportExport();
    private static final int LOCATION_PERMISSION = 7401;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private MethodChannel.Result pending;
    private CancellationSignal cancellation;
    private LocationListener listener;
    private Runnable timeout;
    private boolean permissionInFlight;

    @Override public void configureFlutterEngine(FlutterEngine engine) {
        super.configureFlutterEngine(engine);
        IntroductionPreferences.register(this, engine);
        if (getPackageName().equals("id.ac.fishcare.m0.tests")) {
            getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "fishcare/report_export")
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("save")) reportExport.save(this, call.argument("bytes"), call.argument("name"), result);
                else result.notImplemented();
            });
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "fishcare/location")
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("cancel")) {
                    fail("cancelled", "Pengambilan lokasi dibatalkan.");
                    result.success(null);
                } else if (call.method.equals("getCurrentLocation")) {
                    if (pending != null || permissionInFlight) {
                        result.error("busy", "Pengambilan/izin lokasi masih berlangsung.", null);
                        return;
                    }
                    pending = result;
                    if (!hasLocationPermission()) {
                        permissionInFlight = true;
                        requestPermissions(new String[]{Manifest.permission.ACCESS_COARSE_LOCATION,
                            Manifest.permission.ACCESS_FINE_LOCATION}, LOCATION_PERMISSION);
                    } else acquire(result);
                } else result.notImplemented();
            });
    }

    private boolean hasLocationPermission() {
        return checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            || checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    @Override public void onRequestPermissionsResult(int code, String[] permissions, int[] results) {
        super.onRequestPermissionsResult(code, permissions, results);
        if (code != LOCATION_PERMISSION) return;
        permissionInFlight = false;
        if (pending == null) return;
        if (!hasLocationPermission()) {
            fail("permission_denied", "Izin lokasi ditolak. Coba lagi atau pilih lokasi manual; jika dialog tidak muncul, ubah izin di Pengaturan Android.");
        } else acquire(pending);
    }

    @SuppressWarnings("deprecation")
    private void acquire(MethodChannel.Result token) {
        LocationManager manager = (LocationManager) getSystemService(LOCATION_SERVICE);
        try {
            if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                fail("service_off", "GPS/layanan lokasi dimatikan. Aktifkan lokasi, coba lagi, atau pilih lokasi manual.");
                return;
            }
            boolean fine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
            String provider = fine && manager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                ? LocationManager.GPS_PROVIDER
                : manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ? LocationManager.NETWORK_PROVIDER : null;
            if (provider == null) {
                fail("service_off", "GPS/layanan lokasi tidak tersedia. Aktifkan lokasi atau pilih lokasi manual.");
                return;
            }
            timeout = () -> { if (pending == token) fail("timeout", "Lokasi belum diperoleh dalam 30 detik. Coba lagi atau pilih lokasi manual."); };
            handler.postDelayed(timeout, 30000);
            if (Build.VERSION.SDK_INT >= 30) {
                cancellation = new CancellationSignal();
                manager.getCurrentLocation(provider, cancellation, getMainExecutor(), location -> complete(token, location));
            } else {
                listener = new LocationListener() {
                    @Override public void onLocationChanged(Location location) { complete(token, location); }
                    @Override public void onProviderDisabled(String provider) { if (pending == token) fail("service_off", "Layanan lokasi dimatikan. Coba lagi atau pilih lokasi manual."); }
                    @Override public void onProviderEnabled(String provider) {}
                    @Override public void onStatusChanged(String provider, int status, Bundle extras) {}
                };
                manager.requestSingleUpdate(provider, listener, Looper.getMainLooper());
            }
        } catch (SecurityException error) { fail("permission_denied", "Izin lokasi tidak tersedia. Pilih lokasi manual atau coba lagi."); }
        catch (RuntimeException error) { fail("location_failed", "Pengambilan lokasi gagal. Coba lagi atau pilih lokasi manual."); }
    }

    private void complete(MethodChannel.Result token, Location location) {
        if (pending != token) return;
        if (location == null) { fail("location_failed", "Koordinat belum tersedia. Coba lagi atau pilih lokasi manual."); return; }
        Map<String, Object> coordinates = new HashMap<>();
        coordinates.put("latitude", location.getLatitude());
        coordinates.put("longitude", location.getLongitude());
        coordinates.put("accuracy", location.hasAccuracy() ? (double) location.getAccuracy() : null);
        coordinates.put("approximate", checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED);
        pending = null;
        clean();
        token.success(coordinates);
    }

    private void fail(String code, String message) {
        MethodChannel.Result token = pending;
        pending = null;
        clean();
        if (token != null) token.error(code, message, null);
    }

    private void clean() {
        if (timeout != null) handler.removeCallbacks(timeout);
        timeout = null;
        if (cancellation != null) cancellation.cancel();
        cancellation = null;
        if (listener != null) {
            try { ((LocationManager) getSystemService(LOCATION_SERVICE)).removeUpdates(listener); }
            catch (RuntimeException ignored) {}
        }
        listener = null;
    }
    @Override protected void onStop() { fail("cancelled", "Pengambilan lokasi dihentikan saat aplikasi tidak terlihat."); super.onStop(); }
    @Override protected void onActivityResult(int requestCode, int resultCode, android.content.Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == ReportExport.REQUEST) reportExport.receive(this, resultCode, data);
    }
    @Override protected void onDestroy() { reportExport.dispose(); clean(); super.onDestroy(); }
}
