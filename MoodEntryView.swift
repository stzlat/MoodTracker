// File: MoodEntryView.swift
import SwiftUI

// View for logging a mood entry
struct MoodEntryView: View {
    // Environment property to dismiss the view
    @Environment(\.dismiss) var dismiss
    
    // Get the current theme from AppStorage
    @AppStorage("selectedTheme") private var selectedTheme = "Green"
    
    // State variables to track user selections
    @State private var isCurrentMood = true  // Tracks if logging current or past mood
    @State private var selectedDate = Date() // For date selection
    @State private var selectedTime = Date() // For time selection
    @State private var selectedMood: String = "Happy" // Default mood selection
    @State private var selectedSubMood: String = ""   // Sub-mood selection
    @State private var notes: String = ""             // User notes
    
    // Dictionary of available moods with emojis and sub-moods
    let moods: [String: (emoji: String, subMoods: [String])] = [
        "Happy": ("😊", ["Joyful", "Grateful", "Content", "Excited", "Hopeful"]),
        "Calm": ("😌", ["Relaxed", "At ease", "Meditation"]),
        "Neutral": ("😐", ["Detached", "Numbed", "Bored", "Normal"]),
        "Sad": ("😔", ["Lonely", "Heartbroken", "Disappointed", "Grieving"]),
        "Stressed": ("😥", ["Anxious", "Overwhelmed", "Worried", "Burned Out"]),
        "Angry": ("😠", ["Irritated", "Frustrated", "Resentful", "Furious"]),
        "Tired": ("😴", ["Sleepy", "No motivation", "Drained", "Burnt Out"]),
        "Sick": ("🤒", ["Cold", "In Pain", "Period", "Other"]),
        "Unknown": ("❓", ["The feelings can't be named"])
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background color that fills the entire screen
                getBackgroundColor()
                    .ignoresSafeArea(.all)
                
                Form {
                    // Section for current/previous mood toggle
                    Section(header: Text("Is this your current mood?")) {
                        Picker("", selection: $isCurrentMood) {
                            Text("Current").tag(true)
                            Text("Previous").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())  // Shows as segmented control
                    }
                    
                    // Show date/time pickers only for previous moods
                    if !isCurrentMood {
                        Section(header: Text("When did you feel this way?")) {
                            DatePicker("Select Date", selection: $selectedDate,
                                       displayedComponents: [.date])
                            DatePicker("Select Time", selection: $selectedTime,
                                       displayedComponents: [.hourAndMinute])
                        }
                    }
                    
                    // Mood selection section
                    Section(header: Text("Select Your Mood")) {
                        // Main mood picker
                        Picker("Main Mood", selection: $selectedMood) {
                            ForEach(moods.keys.sorted(), id: \.self) { mood in
                                Text("\(moods[mood]?.emoji ?? "") \(mood)")
                                    .tag(mood)
                            }
                        }
                        
                        // Show sub-mood picker only if the selected mood has sub-moods
                        if let subMoods = moods[selectedMood]?.subMoods, !subMoods.isEmpty {
                            Picker("Optional Detail", selection: $selectedSubMood) {
                                Text("None").tag("")  // Optional "none" selection
                                ForEach(subMoods, id: \.self) { subMood in
                                    Text(subMood).tag(subMood)
                                }
                            }
                        }
                    }
                    
                    // Notes section
                    Section(header: Text("Add Notes (Optional)")) {
                        TextEditor(text: $notes)
                            .frame(height: 100)  // Fixed height text editor
                    }
                }
                .scrollContentBackground(.hidden) // Hide the default form background
                .background(Color.clear) // Make form background transparent
            }
            .navigationTitle("Log Mood")  // View title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Save button in top-right
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMoodEntry()  // Save the entry
                        dismiss()        // Close the view
                    }
                }
                
                // Cancel button in top-left
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()  // Just close without saving
                    }
                }
            }
            .preferredColorScheme(getColorScheme())
        }
    }
    
    // Theme-related functions
    private func getColorScheme() -> ColorScheme? {
        switch selectedTheme {
        case "Dark":
            return .dark
        default:
            return nil // For Green theme, use system default
        }
    }
    
    private func getBackgroundColor() -> Color {
        switch selectedTheme {
        case "Dark":
            return Color.black
        default:
            return Color.adaptiveGreenBackground // Green background for default theme
        }
    }
    
    // Saves the current mood entry to UserDefaults
    func saveMoodEntry() {
        // Create a new mood entry with current selections
        let entry = MoodEntry(
            date: isCurrentMood ? Date() : combineDateTime(date: selectedDate, time: selectedTime),
            mainMood: selectedMood,
            subMood: selectedSubMood.isEmpty ? nil : selectedSubMood,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Load existing entries, append new one, and save back
        var savedEntries = loadMoodEntries()
        savedEntries.append(entry)
        
        // Encode and save to UserDefaults
        if let data = try? JSONEncoder().encode(savedEntries) {
            UserDefaults.standard.set(data, forKey: "moodEntries")
        }

        //print("Mood saved: \(entry)")  // Debug print
    }
    
    // FIXED: Loads saved mood entries from UserDefaults
    func loadMoodEntries() -> [MoodEntry] {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            return decoded
        }
        return []  // Return empty array if none exist
    }
    
    // Combines separate date and time into a single Date object
    func combineDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute,
            second: timeComponents.second
        )) ?? Date()  // Fallback to current date if combination fails
    }
}
