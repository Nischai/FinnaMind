# FinnaMind SMS Reader

A Flutter application that reads SMS messages and parses their content.

## Features

- Requests SMS permissions from the user
- Reads incoming SMS messages
- Parses message content (extracts numbers, dates, URLs, and keywords from messages)
- Displays both original and parsed message content
- Real-time updates when new messages arrive

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio or VS Code with Flutter extensions
- An Android device or emulator (iOS doesn't support SMS reading)

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Connect an Android device or start an emulator
5. Run `flutter run` to start the app

## How It Works

1. When the app starts, it checks if it has SMS permissions
2. If permissions are not granted, it shows a button to request them
3. Once permissions are granted, it fetches and displays recent SMS messages
4. Each message is parsed using the `MessageParser` class
5. Both the original message and the parsed result are displayed in the list
6. The app listens for new incoming messages and updates the UI in real-time

## Customizing Message Parsing

To customize how messages are parsed, modify the `MessageParser` class. The current implementation extracts:
- Numbers (account numbers, amounts, codes)
- Dates in common formats
- URLs
- Keywords related to common SMS notifications

## Permissions

This app requires the following permissions:
- `READ_SMS`: To read SMS messages
- `RECEIVE_SMS`: To receive notifications about new SMS messages

These permissions are considered sensitive and require explicit user approval.

## Project Structure

- `lib/main.dart`: Main application UI and logic
- `lib/message_parser.dart`: Utility for parsing SMS content
- `lib/sms_service.dart`: Service for listening to incoming SMS messages
- `android/`: Native Android code for SMS permissions and receivers