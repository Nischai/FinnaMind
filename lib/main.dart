import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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
      title: 'FinnaMind',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SmsReaderScreen(),
    );
  }
}

class SmsMessage {
  final String sender;
  final String body;
  final DateTime date;

  SmsMessage({
    required this.sender,
    required this.body,
    required this.date,
  });
}

class SmsReaderScreen extends StatefulWidget {
  const SmsReaderScreen({Key? key}) : super(key: key);

  @override
  State<SmsReaderScreen> createState() => _SmsReaderScreenState();
}

class _SmsReaderScreenState extends State<SmsReaderScreen> {
  final SmsService _smsService = SmsService();
  final List<SmsMessage> _messages = [];
  bool _hasPermission = false;
  SmsMessage? _selectedMessage;
  Map<String, dynamic>? _parsedData;
  StreamSubscription? _smsSubscription;
  bool _isListeningForSms = false;
  
  // For manual message entry
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
    // Add some example messages
    _addExampleMessages();
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    _senderController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      _startListeningForSms();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      _startListeningForSms();
    }
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
    final parsedData = MessageParser.parse(newMessage.body);
    
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

  void _addExampleMessages() {
    final examples = [
      SmsMessage(
        sender: 'Bank',
        body: 'Your account balance is \$1,245.67 as of 04/13/2025. Visit https://mybank.com for details.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SmsMessage(
        sender: 'Security',
        body: 'Your verification code is 123456. It expires in 10 minutes.',
        date: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      SmsMessage(
        sender: 'Delivery',
        body: 'Your package #AB123456 will be delivered on 04/15/2025 between 10:00-12:00.',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    
    setState(() {
      _messages.addAll(examples);
    });
  }

  void _addNewMessage() {
    if (_senderController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both sender and message')),
      );
      return;
    }
    
    final newMessage = SmsMessage(
      sender: _senderController.text,
      body: _messageController.text,
      date: DateTime.now(),
    );
    
    setState(() {
      _messages.insert(0, newMessage);
      _selectedMessage = newMessage;
      _parsedData = MessageParser.parse(newMessage.body);
    });
    
    // Clear the text fields
    _senderController.clear();
    _messageController.clear();
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  void _parseMessage(SmsMessage message) {
    final parsedData = MessageParser.parse(message.body);
    
    setState(() {
      _selectedMessage = message;
      _parsedData = parsedData;
    });
  }

  void _pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _messageController.text = data.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinnaMind'),
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
      body: Column(
        children: [
          // Permission request section
          if (!_hasPermission)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
              ),
            ),
          
          // Input section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    labelText: 'Sender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: _pasteFromClipboard,
                      tooltip: 'Paste from clipboard',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addNewMessage,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Message & Parse'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(thickness: 1),
          
          // Messages and parsed data
          Expanded(
            child: Row(
              children: [
                // Messages list
                Expanded(
                  flex: 1,
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.separated(
                          itemCount: _messages.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            
                            return ListTile(
                              title: Text(
                                message.sender,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                message.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _parseMessage(message),
                              selected: _selectedMessage == message,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  message.sender[0].toUpperCase(),
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
                
                // Vertical divider
                const VerticalDivider(thickness: 1),
                
                // Parsed data section
                if (_selectedMessage != null && _parsedData != null)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.grey[50],
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
                              'Date: ${_selectedMessage!.date.toString()}',
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
                            Text(_selectedMessage!.body),
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
                  )
                else
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a message to see parsed data',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
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