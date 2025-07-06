//  File: MoodTrackerApp.swift
//

// Import the SwiftUI framework which provides tools for building user interfaces
import SwiftUI

// The @main attribute identifies this as the entry point of the application
@main
// Define the main app structure that conforms to the App protocol
struct MoodTrackerApp: App {
    // The body property is required by the App protocol and returns the app's content
    var body: some Scene {
        // WindowGroup represents the app's window(s) on macOS and the main screen on iOS
        WindowGroup {
            // ContentView is the root view of your application
            ContentView()
                // On macOS, you might add window configuration here
                // On iOS, this will fill the entire screen
        }
    }
}
