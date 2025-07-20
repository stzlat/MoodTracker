# Moodiary: Mood Tracker iOS Application
Moodiary is an iOS application built with SwiftUI, designed to help users track their emotional well-being through daily mood logging, pattern analysis, and visual trend charts. The app uses Google Firebase as a Backend-as-a-Service (BaaS) for secure user authentication and scalable data storage.


##Setup Instructions
To run the project locally:

### 1) Clone the Repository
Use Git to clone the repo.

### 2) Set Up Firebase
- Create a Firebase project at Firebase Console.
- Register your iOS app and download the GoogleService-Info.plist file.
- Place the file in the Xcode project root and add it to the app target.

### 3) Install Dependencies
Open the project in Xcode (.xcodeproj or .xcworkspace), which auto-installs packages via Swift Package Manager.

### 4) Firebase Configuration
Firebase is initialized in MoodTrackerApp.swift. Ensure it’s linked to your Firebase setup.

### 5) Configure Firestore Rules
To protect user data, set up Firebase Firestore rules so users only access their own documents.

##Running the App
-Select a simulator or device in Xcode and press Cmd + R.
-Log in or register using Firebase Auth.
-Access mood logging, analytics (calendar and charts), and settings (reminders, themes, export data).


##Version 1.2 

## Version 1.1  
<img width="800" alt="Version 1.1 Full App" src="https://github.com/user-attachments/assets/bd1ba84e-8de4-4e96-8983-15a288afd829" />  

## Version 1.0  
<div style="display: flex; gap: 10px;">
  <img width="250" alt="Screen 1" src="https://github.com/user-attachments/assets/330678e7-b2a8-402c-90d9-67aa7309d3a9" />
  <img width="250" alt="Screen 2" src="https://github.com/user-attachments/assets/2bba7dd9-f416-480e-821f-6782b2ab169f" />
  <img width="250" alt="Screen 3" src="https://github.com/user-attachments/assets/9d11eaa2-5fcb-4615-b2d4-5bfef588c9c2" />
</div>
