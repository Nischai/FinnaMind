package com.finnamind.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.provider.Telephony
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.finnamind.sms/sms"
    private var smsReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "registerSmsReceiver" -> {
                    registerSmsReceiver()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun registerSmsReceiver() {
        if (smsReceiver != null) {
            return
        }

        val intentFilter = IntentFilter()
        intentFilter.addAction(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                    val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                    
                    for (message in messages) {
                        val sender = message.displayOriginatingAddress
                        val body = message.displayMessageBody
                        val timestamp = message.timestampMillis
                        
                        Log.d("SmsReceiver", "SMS received from: $sender")
                        
                        val smsData = HashMap<String, Any>()
                        smsData["sender"] = sender
                        smsData["body"] = body
                        smsData["timestamp"] = timestamp
                        
                        activity.runOnUiThread {
                            methodChannel?.invokeMethod("onSmsReceived", smsData)
                        }
                    }
                }
            }
        }

        registerReceiver(smsReceiver, intentFilter)
        Log.d("MainActivity", "SMS receiver registered")
    }

    override fun onDestroy() {
        if (smsReceiver != null) {
            unregisterReceiver(smsReceiver)
            smsReceiver = null
        }
        super.onDestroy()
    }
}