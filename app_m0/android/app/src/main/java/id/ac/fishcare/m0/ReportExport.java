package id.ac.fishcare.m0;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import java.io.OutputStream;
import io.flutter.plugin.common.MethodChannel;

/** One user-selected document; no database writes or storage permission. */
final class ReportExport {
    static final int REQUEST = 7501;
    private MethodChannel.Result pending;
    private byte[] bytes;

    void save(Activity activity, byte[] content, String name, MethodChannel.Result result) {
        if (pending != null) { result.error("busy", "Ekspor masih berlangsung.", null); return; }
        if (content == null || content.length == 0 || name == null) {
            result.error("invalid", "Isi laporan tidak tersedia.", null); return;
        }
        pending = result;
        bytes = content;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        intent.putExtra(Intent.EXTRA_TITLE, name);
        try { activity.startActivityForResult(intent, REQUEST); }
        catch (RuntimeException error) { finishError(); }
    }

    void receive(Activity activity, int resultCode, Intent data) {
        if (pending == null) return;
        if (resultCode != Activity.RESULT_OK) { finish(false); return; }
        Uri uri = data == null ? null : data.getData();
        if (uri == null) { finishError(); return; }
        final byte[] content = bytes;
        new Thread(() -> {
            try (OutputStream output = activity.getContentResolver().openOutputStream(uri, "w")) {
                if (output == null) throw new java.io.IOException("No stream");
                output.write(content);
                output.flush();
            } catch (Exception error) {
                // A provider may leave a partial file. Never report that as success.
                activity.runOnUiThread(this::finishError);
                return;
            }
            activity.runOnUiThread(() -> finish(true));
        }, "FishCare-report-export").start();
    }

    private void finish(boolean saved) {
        MethodChannel.Result token = pending; pending = null; bytes = null;
        if (token != null) token.success(saved);
    }
    private void finishError() {
        MethodChannel.Result token = pending; pending = null; bytes = null;
        if (token != null) token.error("save_failed", "Laporan gagal disimpan; file tujuan mungkin belum lengkap.", null);
    }
    void dispose() { finishError(); }
}
