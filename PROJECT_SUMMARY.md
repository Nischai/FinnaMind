# FinnaMind - Project Summary

## Overview

FinnaMind is a Flutter application designed to read SMS messages on Android devices, parse the content of those messages, and display both the original and parsed information to the user. The app demonstrates how to:

1. Request and handle SMS permissions
2. Read existing SMS messages from the device
3. Listen for new incoming SMS messages in real-time
4. Parse message content to extract useful information
5. Display the parsed data in a user-friendly interface

## Key Features

- **Permission Handling**: Requests SMS read permissions from the user
- **Message Reading**: Reads existing SMS messages from the device inbox
- **Real-time Updates**: Listens for new incoming SMS messages
- **Message Parsing**: Extracts useful information from messages:
  - Numbers (account numbers, amounts, codes)
  - Dates in common formats
  - URLs
  - Keywords related to common SMS notifications
- **User Interface**: Clean, modern UI with a list of messages and detailed view of selected messages

## Technical Implementation

### Flutter Components

- **Main App**: Standard Flutter application structure with Material Design
- **SmsReaderScreen**: Main screen that handles permissions, displays messages, and shows parsed data
- **MessageParser**: Utility class for parsing SMS content
- **SmsService**: Service for listening to incoming SMS messages in real-time

### Native Android Components

- **AndroidManifest.xml**: Configured with necessary SMS permissions
- **MainActivity.kt**: Implements method channel for communication between Flutter and native code
- **SmsReceiver.kt**: BroadcastReceiver for handling incoming SMS messages

### Permissions

The app requires the following Android permissions:
- `READ_SMS`: To access existing SMS messages
- `RECEIVE_SMS`: To receive notifications about new SMS messages

## Architecture

The app follows a simple architecture:

1. **UI Layer**: Flutter widgets for displaying messages and parsed data
2. **Service Layer**: SmsService for handling SMS-related operations
3. **Utility Layer**: MessageParser for extracting information from messages
4. **Native Bridge**: Method channels for communication between Flutter and native Android code

## Security Considerations

- SMS messages often contain sensitive information, so the app does not store or transmit message content
- Permissions are requested at runtime and the app functions only when permissions are granted
- The app clearly explains why it needs SMS permissions before requesting them

## Future Enhancements

Potential improvements for the app:

1. **Custom Parsing Rules**: Allow users to define custom parsing rules for specific message types
2. **Message Categories**: Automatically categorize messages (banking, authentication, marketing, etc.)
3. **Notifications**: Send notifications for important messages based on content
4. **Data Export**: Allow exporting parsed data to CSV or other formats
5. **Message Search**: Add search functionality to find specific messages
6. **Message Filtering**: Filter messages by sender, content, or parsed data
7. **Dark Mode**: Add support for dark mode
8. **Localization**: Add support for multiple languages

## Building and Running

To build and run the app:

1. Ensure Flutter SDK is installed
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Connect an Android device or start an emulator
5. Run `flutter run` to start the app

Note: This app is for Android only, as iOS does not allow third-party apps to read SMS messages.