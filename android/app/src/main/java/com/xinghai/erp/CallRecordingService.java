package com.xinghai.erp;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.media.MediaRecorder;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Locale;
import java.util.UUID;


public class CallRecordingService extends Service {
    private static final String TAG = "CallRecordingService";
    private static final String CHANNEL_ID = "call_recording_channel";
    private static final int NOTIFICATION_ID = 1001;

    private final IBinder binder = new LocalBinder();
    private MediaRecorder mediaRecorder;
    private String currentRecordingPath;
    private boolean isRecording = false;
    private String currentCallNumber;
    private Handler handler;
    private SharedPreferences prefs;

    // API配置 - 需要替换为实际服务器地址
    private static final String API_BASE_URL = "http://47.103.11.151:38080";
    private static final String UPLOAD_URL = API_BASE_URL + "/api/fsm/recordings/upload";

    public class LocalBinder extends Binder {
        public CallRecordingService getService() {
            return CallRecordingService.this;
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        handler = new Handler(Looper.getMainLooper());
        prefs = getSharedPreferences("call_recording", MODE_PRIVATE);
        createNotificationChannel();
        Log.d(TAG, "CallRecordingService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, createNotification());

        // 处理来自CallStateReceiver的命令
        if (intent != null) {
            String action = intent.getAction();
            if ("android.intent.action.START_RECORDING".equals(action)) {
                String phoneNumber = intent.getStringExtra("phone_number");
                startRecording(phoneNumber != null ? phoneNumber : "unknown");
            } else if ("android.intent.action.STOP_RECORDING".equals(action)) {
                stopRecording();
            }
        }

        Log.d(TAG, "CallRecordingService started");
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("星海工程师")
                .setContentText("通话录音服务运行中")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "通话录音",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("保持通话录音服务运行");
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    /**
     * 开始录音（通话建立时由系统调用）
     */
    public void startRecording(String phoneNumber) {
        if (isRecording) {
            Log.w(TAG, "Already recording, stop first");
            stopRecording();
        }

        this.currentCallNumber = phoneNumber;

        // 创建录音目录
        File recordingDir = new File(getFilesDir(), "recordings");
        if (!recordingDir.exists()) {
            recordingDir.mkdirs();
        }

        // 生成文件名：时间_号码.wav
        String timeStr = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
        String fileName = "CALL_" + timeStr + "_" + sanitizeFileName(phoneNumber) + ".m4a";
        currentRecordingPath = new File(recordingDir, fileName).getAbsolutePath();

        try {
            mediaRecorder = new MediaRecorder();
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.VOICE_CALL);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
                mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
            } else {
                mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
                mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            }

            mediaRecorder.setAudioEncodingBitRate(128000);
            mediaRecorder.setAudioSamplingRate(44100);
            mediaRecorder.setOutputFile(currentRecordingPath);

            mediaRecorder.prepare();
            mediaRecorder.start();
            isRecording = true;

            Log.d(TAG, "Recording started: " + currentRecordingPath);
            Log.d(TAG, "Call number: " + phoneNumber);

        } catch (IOException e) {
            Log.e(TAG, "Failed to start recording", e);
            cleanupRecording();
        } catch (IllegalStateException e) {
            Log.e(TAG, "Illegal state for recording", e);
            cleanupRecording();
        }
    }

    /**
     * 停止录音（通话结束时由系统调用）
     */
    public void stopRecording() {
        if (!isRecording) {
            return;
        }

        try {
            if (mediaRecorder != null) {
                mediaRecorder.stop();
                mediaRecorder.release();
                mediaRecorder = null;
            }
            isRecording = false;
            Log.d(TAG, "Recording stopped: " + currentRecordingPath);

            // 录音结束，自动上传到服务器
            if (currentRecordingPath != null && new File(currentRecordingPath).exists()) {
                autoUpload(currentRecordingPath, currentCallNumber);
            }

        } catch (IllegalStateException e) {
            Log.e(TAG, "Failed to stop recording", e);
            cleanupRecording();
        }
    }

    /**
     * 自动上传录音到服务器
     */
    private void autoUpload(String filePath, String phoneNumber) {
        new Thread(() -> {
            try {
                uploadRecording(filePath, new MainActivity.Callback() {
                    @Override
                    public void onSuccess(Object result) {
                        Log.d(TAG, "Auto upload success: " + filePath);
                        // 上传成功后可以删除本地文件节省空间
                        // deleteRecording(filePath);
                    }

                    @Override
                    public void onError(String error) {
                        Log.e(TAG, "Auto upload failed: " + error);
                    }
                }, phoneNumber);
            } catch (Exception e) {
                Log.e(TAG, "Auto upload exception", e);
            }
        }).start();
    }

    /**
     * 上传录音文件到服务器
     */
    public void uploadRecording(String filePath, MainActivity.Callback callback, String phoneNumber) {
        File file = new File(filePath);
        if (!file.exists()) {
            callback.onError("File not found: " + filePath);
            return;
        }

        final String uploadUrl = UPLOAD_URL;

        new Thread(() -> {
            HttpURLConnection connection = null;
            try {
                // 读取工程师ID（从本地存储的登录信息）
                long engineerId = prefs.getLong("engineer_id", 1);
                String engineerName = prefs.getString("engineer_name", "未知");

                URL url = new URL(uploadUrl);
                connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("POST");
                connection.setDoOutput(true);
                connection.setRequestProperty("Content-Type", "multipart/form-data; boundary=----FormBoundary7MA4YWfTkTrErAu6");
                connection.setRequestProperty("Authorization", "Bearer " + getStoredToken());

                // 写入multipart form data
                String boundary = "----FormBoundary7MA4YWfTkTrErAu6";
                OutputStream os = connection.getOutputStream();

                // 添加工程师信息字段
                os.write(("--" + boundary + "\r\n").getBytes());
                os.write(("Content-Disposition: form-data; name=\"engineerId\"\r\n\r\n" + engineerId + "\r\n").getBytes());

                os.write(("--" + boundary + "\r\n").getBytes());
                os.write(("Content-Disposition: form-data; name=\"engineerName\"\r\n\r\n" + engineerName + "\r\n").getBytes());

                os.write(("--" + boundary + "\r\n").getBytes());
                os.write(("Content-Disposition: form-data; name=\"phoneNumber\"\r\n\r\n" + (phoneNumber != null ? phoneNumber : "") + "\r\n").getBytes());

                os.write(("--" + boundary + "\r\n").getBytes());
                os.write(("Content-Disposition: form-data; name=\"file\"; filename=\"" + file.getName() + "\"\r\n").getBytes());
                os.write(("Content-Type: audio/m4a\r\n\r\n").getBytes());

                // 写入文件内容
                InputStream fis = java.io.FileInputStream(file);
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = fis.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
                fis.close();

                os.write(("\r\n--" + boundary + "--\r\n").getBytes());
                os.flush();
                os.close();

                int responseCode = connection.getResponseCode();
                Log.d(TAG, "Upload response code: " + responseCode);

                if (responseCode == 200 || responseCode == 201) {
                    // 读取响应
                    InputStream is = connection.getInputStream();
                    java.io.BufferedReader reader = new java.io.BufferedReader(
                            new java.io.InputStreamReader(is));
                    StringBuilder response = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        response.append(line);
                    }
                    reader.close();

                    Map<String, Object> result = new HashMap<>();
                    result.put("success", true);
                    result.put("filePath", filePath);
                    result.put("response", response.toString());
                    callback.onSuccess(result);
                } else {
                    callback.onError("HTTP " + responseCode);
                }

            } catch (Exception e) {
                Log.e(TAG, "Upload failed", e);
                callback.onError(e.getMessage());
            } finally {
                if (connection != null) {
                    connection.disconnect();
                }
            }
        }).start();
    }

    public void uploadRecording(String filePath, MainActivity.Callback callback) {
        uploadRecording(filePath, callback, null);
    }

    /**
     * 获取本地录音文件列表
     */
    public List<Map<String, Object>> getRecordingList() {
        List<Map<String, Object>> list = new ArrayList<>();
        File recordingDir = new File(getFilesDir(), "recordings");
        if (!recordingDir.exists()) {
            return list;
        }

        File[] files = recordingDir.listFiles();
        if (files == null) {
            return list;
        }

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US);

        for (File file : files) {
            if (file.isFile() && file.getName().endsWith(".m4a")) {
                Map<String, Object> item = new HashMap<>();
                item.put("fileName", file.getName());
                item.put("filePath", file.getAbsolutePath());
                item.put("fileSize", file.length());
                item.put("duration", getAudioDuration(file.getAbsolutePath()));
                item.put("createdAt", sdf.format(new Date(file.lastModified())));
                list.add(item);
            }
        }
        return list;
    }

    /**
     * 获取音频时长（毫秒）
     */
    private long getAudioDuration(String filePath) {
        try {
            MediaRecorder mr = new MediaRecorder();
            mr.setDataSource(filePath);
            mr.prepare();
            long duration = mr.getDuration();
            mr.release();
            return duration;
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * 删除录音文件
     */
    public void deleteRecording(String filePath) {
        File file = new File(filePath);
        if (file.exists()) {
            boolean deleted = file.delete();
            Log.d(TAG, "Deleted " + filePath + ": " + deleted);
        }
    }

    private String getStoredToken() {
        return prefs.getString("auth_token", "");
    }

    public void saveAuthInfo(long engineerId, String engineerName, String token) {
        prefs.edit()
                .putLong("engineer_id", engineerId)
                .putString("engineer_name", engineerName)
                .putString("auth_token", token)
                .apply();
    }

    private String sanitizeFileName(String name) {
        if (name == null) return "unknown";
        return name.replaceAll("[^a-zA-Z0-9.-]", "_");
    }

    private void cleanupRecording() {
        isRecording = false;
        if (mediaRecorder != null) {
            try {
                mediaRecorder.release();
            } catch (Exception ignored) {}
            mediaRecorder = null;
        }
        if (currentRecordingPath != null) {
            new File(currentRecordingPath).delete();
            currentRecordingPath = null;
        }
    }

    @Override
    public void onDestroy() {
        stopRecording();
        super.onDestroy();
    }
}
