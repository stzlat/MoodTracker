//  File: HomeView.swift

import SwiftUI

struct HomeView: View {
    @State private var showMoodSheet = false
    @State private var moodEntries: [MoodEntry] = []
    @AppStorage("selectedTheme") private var selectedTheme = "Green"
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel // Get the auth state

    private var adaptiveGreenBackground: Color {
        colorScheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ... (The button UI remains the same) ...
                Button(action: {
                    showMoodSheet = true
                }) {
                    Text("How are you feeling today?")
                        .font(.system(size: 19, weight: .bold))
                        .fontWeight(.semibold)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0/255, green: 105/255, blue: 78/255))
                        .border(Color.green.opacity(0.3), width: 1)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)


                // Mood History Snapshot
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recent Moods")
                        .font(.system(size: 18, weight: .bold))
                        // ... (UI is the same, but data source will change) ...
                    
                    // ... (The rest of the view body remains largely the same) ...
                     if moodEntries.isEmpty {
                        Text("No mood entries yet")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(moodEntries.prefix(5)) { entry in
                                // ... (This part is identical) ...
                                HStack(spacing: 12) {
                                    Text(getMoodEmoji(for: entry.mainMood))
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.mainMood)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        HStack {
                                            Text(formatDate(entry.date))
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(formatTime(entry.date))
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(adaptiveGreenBackground)

                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                //.background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Moodiary Home")
            .background(
                selectedTheme == "Dark" ? Color.black :
                selectedTheme == "Green" ? Color.adaptiveGreenBackground :
                Color(.systemBackground)
            )
            .onAppear {
                // Load entries when the view appears
                loadMoodEntries()
            }
            .sheet(isPresented: $showMoodSheet, onDismiss: {
                // Reload entries when the sheet is dismissed
                loadMoodEntries()
            }) {
                MoodEntryView()
            }
        }
    }
    
    // REVISED: Load mood entries from Firestore
    func loadMoodEntries() {
        guard let userID = authViewModel.userSession?.uid else {
            print("DEBUG: Cannot load entries, user not logged in.")
            return
        }
        
        Task {
            do {
                self.moodEntries = try await DatabaseService.shared.fetchMoodEntries(forUserID: userID)
            } catch {
                print("DEBUG: Failed to load mood entries from Firestore: \(error)")
            }
        }
    }
    
    // ... (getMoodEmoji, formatDate, formatTime functions remain unchanged) ...
    // Get emoji for mood
    func getMoodEmoji(for mood: String) -> String {
        let moodEmojis: [String: String] = [
            "Happy": "😊", "Calm": "😌", "Neutral": "😐", "Sad": "😔", "Stressed": "😥",
            "Angry": "😠", "Tired": "😴", "Sick": "🤒", "Unknown": "❓"
        ]
        return moodEmojis[mood] ?? "😐"
    }
    
    // Format date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()), calendar.isDate(date, inSameDayAs: yesterday) { return "Yesterday" }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // Format time for display
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
