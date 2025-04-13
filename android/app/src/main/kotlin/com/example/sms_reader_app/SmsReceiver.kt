package com.example.sms_reader_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            for (message in messages) {
                val sender = message.displayOriginatingAddress
                val body = message.displayMessageBody
                
                Log.d("SmsReceiver", "SMS received from: $sender")
                Log.d("SmsReceiver", "Message body: $body")
                
                // Here you could send the message to Flutter using a method channel
                // This would require additional setup with MethodChannel
            }
        }
    }
}