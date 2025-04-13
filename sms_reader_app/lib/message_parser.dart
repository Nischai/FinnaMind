class MessageParser {
  /// Parses an SMS message and extracts relevant information
  /// 
  /// This is a simple implementation that can be extended based on specific needs.
  /// Currently, it extracts:
  /// - Numbers (like account numbers, amounts, codes)
  /// - Dates in common formats
  /// - URLs
  static Map<String, dynamic> parse(String message) {
    if (message.isEmpty) {
      return {'error': 'Empty message'};
    }

    final result = <String, dynamic>{
      'original': message,
      'numbers': _extractNumbers(message),
      'dates': _extractDates(message),
      'urls': _extractUrls(message),
      'keywords': _extractKeywords(message),
    };

    return result;
  }

  /// Extracts all numbers from the message
  static List<String> _extractNumbers(String message) {
    final RegExp regExp = RegExp(r'\b\d+\b');
    final matches = regExp.allMatches(message);
    
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Extracts dates in common formats
  static List<String> _extractDates(String message) {
    // This pattern matches common date formats like DD/MM/YYYY, MM-DD-YYYY, etc.
    final RegExp regExp = RegExp(
      r'\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}\b'
    );
    final matches = regExp.allMatches(message);
    
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Extracts URLs from the message
  static List<String> _extractUrls(String message) {
    final RegExp regExp = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
    );
    final matches = regExp.allMatches(message);
    
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Extracts common keywords that might be important
  static List<String> _extractKeywords(String message) {
    final List<String> commonKeywords = [
      'payment', 'transaction', 'account', 'credit', 'debit',
      'balance', 'transfer', 'code', 'verify', 'confirmation',
      'approved', 'declined', 'alert', 'notification', 'otp',
      'password', 'username', 'login', 'security', 'bank',
      'card', 'expires', 'bill', 'due', 'paid', 'receipt'
    ];
    
    final List<String> foundKeywords = [];
    final lowerMessage = message.toLowerCase();
    
    for (final keyword in commonKeywords) {
      if (lowerMessage.contains(keyword)) {
        foundKeywords.add(keyword);
      }
    }
    
    return foundKeywords;
  }
}