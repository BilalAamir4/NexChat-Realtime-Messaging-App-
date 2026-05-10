# NexChat — Real-Time Messaging App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-7C3AED?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Version-1.1.0-4F46E5?style=for-the-badge"/>
</p>

> **Connect beyond limits.** NexChat is a feature-rich, real-time messaging application built with Flutter and Firebase — supporting direct chats, group conversations, voice messages, image sharing, presence tracking, push notifications, and a radar-based user discovery system.

---

## Features

### Messaging
- **Real-time direct & group chats** powered by Firestore streams
- **Voice messages** — record, upload to Firebase Storage, and play back inline
- **Image sharing** — pick from gallery or capture with camera, uploaded to Firebase Storage and displayed inline with a tap-to-expand viewer
- **Reply to messages** — swipe right to quote any message
- **Delete messages** — "Delete for me" or "Delete for everyone"
- **Typing indicators** — live animated dots while the other person types
- **Read receipts** — double-tick turns indigo when a message is read
- **Unread badge counts** per conversation

### Auth & Security
- Email & password sign-up / sign-in
- **Phone OTP verification** via Firebase Auth (SMS 2FA)
- Auto-verification on Android (no code entry needed)
- Multi-step registration with username uniqueness check and avatar color picker

### Profile
- **Profile photo upload** — pick an image from gallery or camera, stored in Firebase Storage and synced across all screens in real time

### Groups
- Create groups from existing contacts (2-step flow)
- View group members and edit group name
- Leave group with confirmation
- Group typing indicators and unread counts

### Discovery
- **Radar screen** — animated sweep radar showing all registered users
- Search users by display name or `@username`
- Tap a radar dot to see a floating profile card and start a chat instantly

### Presence & Notifications
- Online/offline status synced via Firebase Realtime Database + Firestore
- "Last seen X mins ago" labels
- **Push notifications** via Firebase Cloud Messaging (FCM)
- Foreground notifications shown as heads-up banners
- Tapping a notification navigates directly to the relevant chat
- In-app **Notifications screen** with unread dots, swipe-to-dismiss, and clear all

### UI & Theming
- Full **dark / light mode** with persistent preference (SharedPreferences)
- Collapsible settings screen with live chat preview
- Custom animated splash screen with constellation network, beam sweep, and ripple burst
- Indigo / violet brand gradient throughout
- Smooth page and element transitions

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State management | Riverpod (providers, notifiers, streams) |
| Backend | Firebase (Auth, Firestore, Storage, Realtime Database, FCM) |
| Local notifications | flutter_local_notifications |
| Audio | record (recording) + just_audio (playback) |
| Image picking | image_picker |
| Permissions | permission_handler |
| Theme persistence | shared_preferences |
| Date formatting | intl |

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0
- Dart >= 3.0
- A Firebase project with the following services enabled:
  - Authentication (Email/Password + Phone)
  - Cloud Firestore
  - Firebase Storage
  - Firebase Realtime Database
  - Firebase Cloud Messaging

### Setup

1. Clone the repository

git clone [https://github.com/BilalAamir4/NexChat-Realtime-Messaging-App-]
cd nexchat

2. Install dependencies

flutter pub get

3. Configure Firebase
  - Run flutterfire configure (recommended), or manually place your google-services.json (Android) and GoogleService-Info.plist (iOS) in the appropriate directories.
  - The generated firebase_options.dart is already wired into main.dart.

4. Android — additional setup
  - Add your SHA-1 and SHA-256 fingerprints in the Firebase Console for Phone Auth.
  - Place an ic_notification.png drawable in android/app/src/main/res/drawable/ for notification icons.
  - Camera and media permissions are declared in AndroidManifest.xml and requested at runtime via permission_handler.

5. Run

flutter run

---

## Firestore Security Rules

rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {
match /users/{uid} {
allow read: if request.auth != null;
allow write: if request.auth.uid == uid;
match /fcmTokens/{token} {
allow read, write: if request.auth.uid == uid;
}
match /notifications/{notifId} {
allow read, write: if request.auth.uid == uid;
}
}
match /chats/{chatId} {
allow read, write: if request.auth.uid in resource.data.participants;
match /messages/{msgId} {
allow read, write: if request.auth.uid in
get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
}
}
}
}

---

## Key Architectural Decisions

- **Riverpod** is used throughout for dependency injection and reactive state. Services are exposed as Provider<T>, streams as StreamProvider, and mutations as AsyncNotifier.
- **Presence** is tracked in Firebase Realtime Database (reliable disconnect detection via onDisconnect) and mirrored to Firestore so the app's presenceProvider can stream it in real time.
- **Optimistic unread counts** are updated atomically using Firestore batched writes alongside lastMessage.
- **Voice messages and images** are uploaded to Firebase Storage before the Firestore document is created, keeping the message model consistent (no URL-less records).
- **Profile photos** are stored in Firebase Storage and the download URL is written to the user's Firestore document, so updates propagate in real time across all screens that stream the user profile.

---

## Roadmap

- [ ] End-to-end encryption
- [ ] Message reactions (emoji)
- [ ] Disappearing messages
- [ ] Video & audio calls (WebRTC)
- [ ] Message search
- [ ] Multi-device session management

---

## License

MIT License — feel free to fork, build on, and share.

---

<p align="center">Built with ❤️ using Flutter & Firebase</p>