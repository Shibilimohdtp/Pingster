# Pingster Chat App

Pingster is a secure, feature-rich chat application built with Flutter and Firebase. It offers end-to-end encryption, real-time messaging, and a variety of modern chat features.

## Features

- **Secure Communication**: End-to-end encryption for all messages
- **Real-time Messaging**: Instant message delivery and updates
- **User Authentication**: Email/password sign-up and login
- **Profile Management**: User profiles with customizable details
- **Chat Management**: Create, delete, and organize chats
- **Message Features**:
  - Edit and delete messages
  - Pin important messages
  - React to messages with emojis
  - Send secret messages with expiration times
- **File Sharing**: Upload and share files in chats
- **Typing Indicators**: See when others are typing
- **Read Receipts**: Know when your messages have been read
- **User Search**: Find and start chats with other users
- **Chat Theming**: Customize the appearance of individual chats
- **Dark Mode**: System-wide dark mode support
- **User Blocking**: Block and unblock users as needed

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Routing**: go_router
- **Encryption**: encrypt package
- **Local Storage**: flutter_secure_storage, shared_preferences

## Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/your-username/Pingster.git
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Firebase:
   - Create a new Firebase project
   - Add an Android and/or iOS app to your Firebase project
   - Download and add the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to your project
   - Enable Email/Password authentication in the Firebase console
   - Create Firestore database and set up security rules

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

- `lib/`
  - `main.dart`: Entry point of the application
  - `app.dart`: Main app configuration
  - `router.dart`: App routing configuration
  - `theme.dart`: App theme definitions
  - `models/`: Data models
  - `providers/`: State management
  - `screens/`: UI screens
  - `services/`: Firebase and encryption services
  - `widgets/`: Reusable UI components

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
