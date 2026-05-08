package com.xinghai.erp;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.telephony.TelephonyManager;
import android.util.Log;

/**
 * 监听电话状态变化，自动开始/停止录音
 *
 * 在 AndroidManifest.xml 中注册：
 * <receiver android:name=".CallStateReceiver">
 *     <intent-filter>
 *         <action android:name="android.intent.action.PHONE_STATE"/>
 *     </intent-filter>
 * </receiver>
 *
 * 需要权限：android.permission.READ_PHONE_STATE
 */
public class CallStateReceiver extends BroadcastReceiver {
    private static final String TAG = "CallStateReceiver";
    private static String lastState = "";
    private static String incomingNumber = "";
    private static boolean wasRinging = false;

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) {
            return;
        }

        if (!intent.getAction().equals("android.intent.action.PHONE_STATE")) {
            return;
        }

        String state = intent.getStringExtra(TelephonyManager.EXTRA_STATE);
        incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER);

        Log.d(TAG, "Phone state changed: " + state + ", number: " + incomingNumber);

        if (state == null) {
            return;
        }

        if (state.equals(TelephonyManager.EXTRA_STATE_IDLE)) {
            // 电话空闲——通话结束，停止录音
            if (wasRinging || !lastState.equals(TelephonyManager.EXTRA_STATE_IDLE)) {
                Log.d(TAG, "Call ended, stopping recording");
                stopRecordingService(context);
                wasRinging = false;
            }
        } else if (state.equals(TelephonyManager.EXTRA_STATE_RINGING)) {
            // 电话响铃中
            Log.d(TAG, "Incoming call ringing: " + incomingNumber);
            wasRinging = true;
        } else if (state.equals(TelephonyManager.EXTRA_STATE_OFFHOOK)) {
            // 电话接通，开始录音
            Log.d(TAG, "Call answered, starting recording for: " + incomingNumber);
            wasRinging = false;
            startRecordingService(context, incomingNumber != null ? incomingNumber : "unknown");
        }

        lastState = state;
    }

    private void startRecordingService(Context context, String phoneNumber) {
        Intent serviceIntent = new Intent(context, CallRecordingService.class);
        serviceIntent.setAction("android.intent.action.START_RECORDING");
        serviceIntent.putExtra("phone_number", phoneNumber);
        context.startService(serviceIntent);
        Log.d(TAG, "Started CallRecordingService for: " + phoneNumber);
    }

    private void stopRecordingService(Context context) {
        Intent serviceIntent = new Intent(context, CallRecordingService.class);
        serviceIntent.setAction("android.intent.action.STOP_RECORDING");
        context.startService(serviceIntent);
        Log.d(TAG, "Stopped CallRecordingService");
    }
}
