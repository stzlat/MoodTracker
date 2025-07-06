//  File: HomeView.swift
//

//  File: HomeView.swift
//

import SwiftUI

struct HomeView: View {
    @State private var showMoodSheet = false
    @State private var moodEntries: [MoodEntry] = []
    @AppStorage("selectedTheme") private var selectedTheme = "Green"
    @Environment(\.colorScheme) var colorScheme

    private var adaptiveGreenBackground: Color {
        colorScheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // "How Are You Feeling Today?" Button - Made bigger with adaptive green background
                Button(action: {
                    showMoodSheet = true
                }) {
                    Text("How are you feeling today?")
                        .font(.system(size: 19, weight: .bold))
                        .fontWeight(.semibold)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity)
                        //.background(adaptiveGreenBackground)
                        //.background(Color(red: 220/255, green: 245/255, blue: 230/255))
                        .background(Color(red: 0/255, green: 105/255, blue: 78/255))
                        .border(Color.green.opacity(0.3), width: 1)
                        //.foregroundColor(.primary)
                        .foregroundColor(.white)
                        //.foregroundColor(Color(red: 0.0, green: 100/255, blue: 0.0))
                        .cornerRadius(15)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)

                // Mood History Snapshot
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Recent Moods")
                                        .font(.system(size: 18, weight: .bold))
                                        .bold()
                                        .padding(.horizontal)

                                    if moodEntries.isEmpty {
                                        Text("No mood entries yet")
                                            .foregroundColor(.secondary)
                                            .italic()
                                            .padding()
                                    } else {
                                        VStack(spacing: 8) {
                                            ForEach(moodEntries.prefix(5)) { entry in
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
                                                //.background(Color.secondary.opacity(0.1))
                                                .background(adaptiveGreenBackground)
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)

                                Spacer()
                            }
                            .navigationTitle("Moodiary Home")
                            .onAppear {
                                loadMoodEntries()
                            }
                            .sheet(isPresented: $showMoodSheet) {
                                MoodEntryView()
                            }
                            .onChange(of: showMoodSheet) { _, newValue in
                                if !newValue {
                                    // Reload mood entries when sheet is dismissed
                                    loadMoodEntries()
                                }
                            }
                            .background(
                                selectedTheme == "Dark" ? Color.black :
                                //selectedTheme == "Light" ? Color.white :
                                selectedTheme == "Green" ? Color.adaptiveGreenBackground :
                                Color(.systemBackground)
                            )
                        }
                    }
                    
                    // Load saved mood entries
                    func loadMoodEntries() {
                        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
                           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
                            moodEntries = decoded.sorted { $0.date > $1.date }
                        }
                    }
                    
                    // Get emoji for mood
                    func getMoodEmoji(for mood: String) -> String {
                        let moodEmojis: [String: String] = [
                            "Happy": "😊",
                            "Calm": "😌",
                            "Neutral": "😐",
                            "Sad": "😔",
                            "Stressed": "😥",
                            "Angry": "😠",
                            "Tired": "😴",
                            "Sick": "🤒",
                            "Unknown": "❓"
                        ]
                        return moodEmojis[mood] ?? "😐"
                    }
                    
                    // Format date for display
                    func formatDate(_ date: Date) -> String {
                        let formatter = DateFormatter()
                        let calendar = Calendar.current
                        
                        if calendar.isDate(date, inSameDayAs: Date()) {
                            return "Today"
                        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
                                  calendar.isDate(date, inSameDayAs: yesterday) {
                            return "Yesterday"
                        } else {
                            formatter.dateFormat = "MMM d"
                            return formatter.string(from: date)
                        }
                    }
                    
                    // Format time for display
                    func formatTime(_ date: Date) -> String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        return formatter.string(from: date)
                    }
                }
