import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service that listens for incoming SMS messages in real-time
class SmsService {
  static const MethodChannel _channel = MethodChannel('com.example.sms_reader_app/sms');
  static final SmsService _instance = SmsService._internal();
  
  factory SmsService() => _instance;
  
  SmsService._internal();
  
  final _smsStreamController = StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream of incoming SMS messages
  Stream<Map<String, dynamic>> get messageStream => _smsStreamController.stream;
  
  /// Initialize the SMS service
  Future<void> initialize() async {
    // Check if we have SMS permission
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      throw Exception('SMS permission not granted');
    }
    
    // Set up method call handler
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Register the SMS receiver on the native side
    try {
      await _channel.invokeMethod('registerSmsReceiver');
    } catch (e) {
      print('Error registering SMS receiver: $e');
    }
  }
  
  /// Handle method calls from the native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSmsReceived':
        final Map<String, dynamic> smsData = Map<String, dynamic>.from(call.arguments);
        _smsStreamController.add(smsData);
        break;
      default:
        print('Unknown method ${call.method}');
    }
  }
  
  /// Dispose the service
  void dispose() {
    _smsStreamController.close();
  }
}