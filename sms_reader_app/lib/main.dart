import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'message_parser.dart';
import 'sms_service.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Reader App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SmsReaderScreen(),
    );
  }
}

class SmsReaderScreen extends StatefulWidget {
  const SmsReaderScreen({Key? key}) : super(key: key);

  @override
  State<SmsReaderScreen> createState() => _SmsReaderScreenState();
}

class _SmsReaderScreenState extends State<SmsReaderScreen> {
  final SmsQuery _query = SmsQuery();
  final SmsService _smsService = SmsService();
  List<SmsMessage> _messages = [];
  bool _hasPermission = false;
  SmsMessage? _selectedMessage;
  Map<String, dynamic>? _parsedData;
  StreamSubscription? _smsSubscription;
  bool _isListeningForSms = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      _fetchMessages();
      _startListeningForSms();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      _fetchMessages();
      _startListeningForSms();
    }
  }

  Future<void> _fetchMessages() async {
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 20,
    );
    
    setState(() {
      _messages = messages;
    });
  }

  Future<void> _startListeningForSms() async {
    if (_isListeningForSms) return;
    
    try {
      await _smsService.initialize();
      _smsSubscription = _smsService.messageStream.listen(_onNewSmsReceived);
      setState(() {
        _isListeningForSms = true;
      });
    } catch (e) {
      print('Error starting SMS listener: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start SMS listener: $e')),
      );
    }
  }

  void _onNewSmsReceived(Map<String, dynamic> smsData) {
    // Create a new SmsMessage from the received data
    final newMessage = SmsMessage(
      sender: smsData['sender'],
      body: smsData['body'],
      date: DateTime.fromMillisecondsSinceEpoch(smsData['timestamp']),
    );
    
    // Parse the message
    final parsedData = MessageParser.parse(newMessage.body ?? '');
    
    // Update the UI
    setState(() {
      // Add the new message to the top of the list
      _messages.insert(0, newMessage);
      
      // Select the new message
      _selectedMessage = newMessage;
      _parsedData = parsedData;
    });
    
    // Show a notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New message from ${newMessage.sender}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            setState(() {
              _selectedMessage = newMessage;
              _parsedData = parsedData;
            });
          },
        ),
      ),
    );
  }

  void _parseMessage(SmsMessage message) {
    final parsedData = MessageParser.parse(message.body ?? '');
    
    setState(() {
      _selectedMessage = message;
      _parsedData = parsedData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Reader'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_hasPermission && _isListeningForSms)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: const Text('Listening'),
                avatar: const Icon(Icons.radio_button_on, color: Colors.green, size: 16),
                backgroundColor: Colors.green[50],
              ),
            ),
        ],
      ),
      body: _hasPermission
          ? Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages found'))
                      : ListView.separated(
                          itemCount: _messages.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            
                            return ListTile(
                              title: Text(
                                message.sender ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                message.body ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _parseMessage(message),
                              selected: _selectedMessage == message,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  (message.sender ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                              trailing: Text(
                                _formatDate(message.date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_selectedMessage != null && _parsedData != null)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.grey[100],
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: ${_selectedMessage!.sender}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${_selectedMessage!.date?.toString() ?? 'Unknown'}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const Divider(),
                            Text(
                              'Original Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_selectedMessage!.body ?? ''),
                            const Divider(),
                            const Text(
                              'Parsed Data:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildParsedDataSection('Numbers', _parsedData!['numbers']),
                            _buildParsedDataSection('Dates', _parsedData!['dates']),
                            _buildParsedDataSection('URLs', _parsedData!['urls']),
                            _buildParsedDataSection('Keywords', _parsedData!['keywords']),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SMS permission is required to read messages',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestPermission,
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
      floatingActionButton: _hasPermission
          ? FloatingActionButton(
              onPressed: _fetchMessages,
              tooltip: 'Refresh',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return _getDayName(date.weekday);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
  
  Widget _buildParsedDataSection(String title, List<dynamic> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text('$title: None found'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: items.map((item) => Chip(
              label: Text(item.toString()),
              backgroundColor: Colors.blue[50],
            )).toList(),
          ),
        ],
      ),
    );
  }
}