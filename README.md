# CoupleConnect - A Partner-Focused Social Platform

Up2Love is an app designed **to help couples stay connected**, share moments, and organize their lives together. With features like messaging, mood tracking, photo sharing, and event planning, CoupleConnect strengthens relationships by providing a shared digital space for couples.

---

## Features

- **User Authentication**: Sign up, log in, and manage your profile.
- **Partner Connection**: Sync with your partner using username and email.
- **Messaging**: Send messages to your partner with a "one message per day" rule.
- **Mood Tracking**: Save, update, and delete mood-related notes.
- **Photo Sharing**: Upload photos with captions, edit captions, and delete photos.
- **Event Planning**: Create, update, and delete events in a shared planner.
- **Profile Management**: Update your profile picture and personal details.
- **Password Reset**: Reset your password via email.

---

## Technologies Used

- **Frontend**: Flutter
- **Backend**: Firebase
  - **Firebase Authentication**: User sign-up, login, and password reset.
  - **Firestore**: Database for user profiles, messages, notes, photos, and events.
  - **Firebase Storage**: Storage for profile pictures and uploaded photos.

---

## Getting Started

Follow these steps to set up and run the project locally.

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Firebase account (for backend services)
- Android Studio or Xcode (for emulator/simulator)

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/couple-connect.git
   cd up2love

2. **Set Up Firebase**:
    - Go to the [Firebase Console](https://console.firebase.google.com/).
    - Create a new project and register your app.
    - Download the `google-services.json` (for Android)and `GoogleService-Info.plist` (for iOS) files.
    - Place these files in the appropriate directories:
        - Android: android/app/
        - iOS: ios/Runner/

3. **Install Dependencies:**
    ```bash
   flutter pub get

4. **Run the App:s:**
    ```bash
   flutter run

---

## Firebase Security Rules
To ensure proper access control, update your Firestore security rules as follows:

```js
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow get: if request.auth != null;
      allow list: if request.auth != null && 
                   (request.query['username'] != null || 
                    request.query['email'] != null);
    }
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
---

## Folder Structure
```
lib/
├── screens/             
├── services/            
│   ├── home_service.dart
│   ├── login_service.dart
│   ├── note_service.dart
│   ├── partner_service.dart
│   ├── photo_service.dart
│   ├── planner_service.dart
│   ├── profile_service.dart
│   └── signup_service.dart
└── main.dart            
```
---

## Contributing
I'm open to contributions! If you'd like to contribute, please follow these steps:
1. Fork the repository
2. Create a new branch
     ```bash
    git checkout -b feature/YourFeatureName
3. Commit your changes 
     ```bash
     git commit -m 'Add some feature'
4. Push to the branch 
     ```bash
     git push origin feature/YourFeatureName
5. Open a pull request.

---

## Acknowledgments
- Thanks to the Flutter and Firebase teams for their amazing tools and documentation.
- Inspired by the need for better digital tools for couples.

---

## Contact
- João Victor
- Email:barbosa.joaodourado@gmail.com
- GitHub: JVDourado