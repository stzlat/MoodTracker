// File: SettingsView.swift
import SwiftUI

struct SettingsView: View {
    // MARK: - Properties
    // Device-specific settings can remain in AppStorage
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("reminderTime") private var reminderTimeData = Data()
    @AppStorage("selectedTheme") private var selectedTheme = "Default"
    
    // EnvironmentObject to get the current user's session
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // State for UI updates
    @State private var reminderTime = Date()
    @State private var showingDataAlert = false
    @State private var showingExportSheet = false
    @State private var showingContactSheet = false
    @State private var showingHelpSheet = false
    @State private var totalEntries = 0 // State for the total entries count
    @State private var showingSignOutAlert = false

    let themes = ["Green", "Dark"]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background color that fills the entire screen
                getBackgroundColor()
                    .ignoresSafeArea(.all)
                
                List {
                    // Account Section
                        Section("Account") {
                            HStack {
                                Text("Logged In As")
                                Spacer()
                                Text(authViewModel.userSession?.email ?? "N/A")
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Button("Sign Out", role: .destructive) {
                                showingSignOutAlert = true
                            }
                        }
                    
                    // Notifications Section
                    Section("Notifications") {
                        Toggle("Daily Reminder", isOn: $dailyReminderEnabled)
                        
                        if dailyReminderEnabled {
                            DatePicker("Reminder Time",
                                     selection: $reminderTime,
                                     displayedComponents: .hourAndMinute)
                                .onChange(of: reminderTime) { _, newValue in
                                    saveReminderTime(newValue)
                                }
                        }
                    }
                    
                    // Appearance Section
                    Section("Appearance") {
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(themes, id: \.self) { theme in
                                Text(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Data Management Section
                    Section("Data Management") {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            // Pass the logged-in user's entries to the Export view
                            Button("Export Data") {
                                showingExportSheet = true
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Button("Clear All Data") {
                                showingDataAlert = true
                            }
                            .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    
                    // About Section
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Entries")
                            Spacer()
                            // Display the count from our state variable
                            Text("\(totalEntries)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Support Section
                    Section("Support") {
                        // ... (This section remains unchanged) ...
                        Button(action: { showingHelpSheet = true }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                                Text("Help & FAQ")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: { showingContactSheet = true }) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.blue)
                                Text("Contact Support")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .onAppear {
                // When the view appears, load settings and fetch the latest entry count
                loadReminderTime()
                fetchTotalEntries()
            }
            .alert("Clear All Data", isPresented: $showingDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your mood entries from your account. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                // Pass the current user's ID to the export view
                if let userId = authViewModel.userSession?.uid {
                    ExportDataView(userID: userId)
                }
            }
            .sheet(isPresented: $showingHelpSheet) {
                HelpView()
            }
            .sheet(isPresented: $showingContactSheet) {
                ContactSupportView()
            }
            // .alert
            .alert("Confirm Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? You will be returned to the login screen.")
            }
            .preferredColorScheme(getColorScheme())
        }
    }
    
    // MARK: - Functions
    private func getColorScheme() -> ColorScheme? {
        selectedTheme == "Dark" ? .dark : nil
    }
    
    private func getBackgroundColor() -> Color {
        switch selectedTheme {
        case "Dark":
            return Color.black
        default:
            // Assuming Color.adaptiveGreenBackground is defined elsewhere, e.g., in an extension
            return Color.green.opacity(0.1)
        }
    }
    
    private func saveReminderTime(_ time: Date) {
        if let encoded = try? JSONEncoder().encode(time) {
            reminderTimeData = encoded
        }
    }
    
    private func loadReminderTime() {
        if let decoded = try? JSONDecoder().decode(Date.self, from: reminderTimeData) {
            reminderTime = decoded
        } else {
            let calendar = Calendar.current
            let components = DateComponents(hour: 20, minute: 0)
            reminderTime = calendar.date(from: components) ?? Date()
        }
    }
    
    // REVISED: Fetches total entries from Firestore
    private func fetchTotalEntries() {
        guard let userID = authViewModel.userSession?.uid else { return }
        Task {
            self.totalEntries = await DatabaseService.shared.getTotalEntriesCount(forUserID: userID)
        }
    }
    
    // REVISED: Clears all data from Firestore for the current user
    private func clearAllData() {
        guard let userID = authViewModel.userSession?.uid else { return }
        Task {
            await DatabaseService.shared.clearAllData(forUserID: userID)
            // Refresh the count after clearing
            fetchTotalEntries()
        }
    }
}

// MARK: - Helper Views (Help, Contact, etc.)
// These views do not need changes unless they also handle user-specific data.
// We only need to modify ExportDataView.

// Help & FAQ Sheet
struct HelpView: View {
    // ... (This view's code remains unchanged) ...
    @Environment(\.presentationMode) var presentationMode
    
    let faqItems = [
        ("How do I add a mood entry?", "Tap the Home tab and select your mood from the available options. You can also add notes to describe your feelings in more detail."),
        ("Can I edit past entries?", "Currently, you can view past entries in the Analytics section. Editing functionality will be available in future updates."),
        ("How is my data stored?", "All your mood data is stored locally on your device and is not shared with anyone. Your privacy is our priority."),
        ("What do the analytics show?", "The Analytics section shows your mood patterns over time, including frequency charts and trends to help you understand your emotional patterns."),
        ("Can I export my data?", "Yes! Go to Settings > Export Data to save your mood tracking data in CSV format."),
        ("How do reminders work?", "Enable daily reminders in Settings to get notifications at your chosen time to track your mood consistently.")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Help & FAQ")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Find answers to common questions about mood tracking")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    ForEach(faqItems, id: \.0) { question, answer in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(question)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(answer)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


// Contact Support Sheet
struct ContactSupportView: View {
    // ... (This view's code remains unchanged) ...
     @Environment(\.presentationMode) var presentationMode
    @State private var message = ""
    @State private var email = ""
    @State private var selectedCategory = "General"
    @State private var showingThankYou = false
    
    let categories = ["General", "Bug Report", "Feature Request", "Data Issues", "Other"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Contact Support")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("We're here to help! Send us your questions or feedback.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.headline)
                            TextField("your.email@example.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.headline)
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Message")
                                .font(.headline)
                            TextEditor(text: $message)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: sendMessage) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Message")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || message.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Contact")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Message Sent!", isPresented: $showingThankYou) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Thank you for your message. We'll get back to you soon!")
            }
        }
    }
    
    private func sendMessage() {
        showingThankYou = true
    }
}

// REVISED: Export Data Sheet to fetch data from Firestore
struct ExportDataView: View {
    @Environment(\.presentationMode) var presentationMode
    let userID: String // Expect a userID to be passed in
    
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Export your mood tracking data as a CSV file")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await exportData()
                    }
                }) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? "Exporting..." : "Export Data")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = exportedFileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
        }
    }
    
    private func exportData() async {
        isExporting = true
        
        do {
            // Create CSV data by fetching from Firestore
            let csvData = try await createCSVData()
            
            // Create temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("mood_data_\(Date().timeIntervalSince1970).csv")
            
            try csvData.write(to: tempURL, atomically: true, encoding: .utf8)
            self.exportedFileURL = tempURL
            self.isExporting = false
            self.showingShareSheet = true
        } catch {
            print("Error writing CSV file: \(error)")
            self.isExporting = false
        }
    }
    
    // REVISED: createCSVData is now async and fetches from Firestore
    private func createCSVData() async throws -> String {
        var csvString = "Date,Main Mood,Sub Mood,Notes\n"
        
        // Get mood entries from Firestore for the current user
        let entries = try await DatabaseService.shared.fetchMoodEntries(forUserID: userID)
            
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for entry in entries {
            let dateString = dateFormatter.string(from: entry.date)
            let mainMood = entry.mainMood
            let subMood = entry.subMood ?? ""
            let notes = entry.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            csvString += "\"\(dateString)\",\"\(mainMood)\",\"\(subMood)\",\"\(notes)\"\n"
        }
        
        return csvString
    }
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel()) // Add a dummy AuthViewModel for preview
    }
}
