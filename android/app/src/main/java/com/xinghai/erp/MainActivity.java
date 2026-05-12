package com.xinghai.erp;

import android.Manifest;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "CallRecording";
    private static final String CHANNEL = "com.xinghai.erp/call_recording";
    private static final int PERMISSION_REQUEST_CODE = 100;

    private CallRecordingService recordingService;
    private boolean serviceBound = false;
    private String[] requiredPermissions = {
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.ANSWER_PHONE_CALLS
    };

    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            CallRecordingService.LocalBinder binder = (CallRecordingService.LocalBinder) service;
            recordingService = binder.getService();
            serviceBound = true;
            Log.d(TAG, "CallRecordingService connected");
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            serviceBound = false;
            recordingService = null;
        }
    };

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // 启动录音服务
        Intent intent = new Intent(this, CallRecordingService.class);
        startService(intent);
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);

        // 注册平台通道
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startRecording":
                            // 通话开始，系统自动录音，不需要手动start
                            result.success(true);
                            break;

                        case "stopRecording":
                            // 通话结束，系统自动停止，不需要手动stop
                            result.success(true);
                            break;

                        case "getRecordings":
                            // 获取录音文件列表
                            if (serviceBound && recordingService != null) {
                                result.success(recordingService.getRecordingList());
                            } else {
                                result.success(new java.util.ArrayList<>());
                            }
                            break;

                        case "uploadRecording":
                            String filePath = call.argument("filePath");
                            if (serviceBound && recordingService != null && filePath != null) {
                                recordingService.uploadRecording(filePath, new Callback() {
                                    @Override
                                    public void onSuccess(Object o) {
                                        new Handler(Looper.getMainLooper()).post(() ->
                                                result.success(o));
                                    }
                                    @Override
                                    public void onError(String error) {
                                        new Handler(Looper.getMainLooper()).post(() ->
                                                result.error("UPLOAD_ERROR", error, null));
                                    }
                                });
                            } else {
                                result.error("SERVICE_NOT_READY", "Recording service not ready", null);
                            }
                            break;

                        case "deleteRecording":
                            String path = call.argument("filePath");
                            if (serviceBound && recordingService != null && path != null) {
                                recordingService.deleteRecording(path);
                                result.success(true);
                            } else {
                                result.success(false);
                            }
                            break;

                        case "checkPermissions":
                            result.success(checkAllPermissions());
                            break;

                        case "requestPermissions":
                            requestAllPermissions();
                            result.success(true);
                            break;

                        default:
                            result.notImplemented();
                    }
                });
    }

    private boolean checkAllPermissions() {
        for (String permission : requiredPermissions) {
            if (ContextCompat.checkSelfPermission(this, permission)
                    != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    private void requestAllPermissions() {
        ActivityCompat.requestPermissions(this, requiredPermissions, PERMISSION_REQUEST_CODE);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (serviceBound) {
            unbindService(serviceConnection);
            serviceBound = false;
        }
    }

    // 回调接口
    public interface Callback {
        void onSuccess(Object result);
        void onError(String error);
    }
}
