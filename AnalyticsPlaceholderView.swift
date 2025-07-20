// File : AnalyticsPlaceholderView.swift

import SwiftUI
import Foundation

// Enhanced Analytics View with Calendar and Charts
struct AnalyticsView: View {
    @State private var entries: [MoodEntry] = []
    @State private var selectedView: AnalyticsViewType = .calendar
    @State private var selectedTimeRange: TimeRange = .weekly
    @State private var smoothTrendLine: Bool = false
    @State private var selectedDate = Date() // Changed from selectedMonth to selectedDate for all ranges
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedTheme") private var selectedTheme = "Default"
    
    enum AnalyticsViewType: String, CaseIterable {
        case calendar = "Calendar"
        case chart = "Chart"
    }
    
    enum TimeRange: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    // Custom green background that adapts to appearance
    private var adaptiveGreenBackground: Color {
        colorScheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // View selector (Calendar/Chart)
                Picker("View Type", selection: $selectedView) {
                    ForEach(AnalyticsViewType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if entries.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No mood data yet")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Start tracking your mood to see analytics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    if selectedView == .calendar {
                        MoodCalendarView(entries: entries)
                    } else {
                        VStack {
                            // Time range selector for charts
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            // Add navigation for all time ranges
                            HStack {
                                Button(action: { changeDate(-1) }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                }
                                
                                Spacer()
                                
                                Text(dateRangeString(from: selectedDate))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: { changeDate(1) }) {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Smooth line toggle
                            Toggle("Smooth Trend Line", isOn: $smoothTrendLine)
                                .padding(.horizontal)
                            
                            MoodChartView(entries: entries, timeRange: selectedTimeRange, smoothLine: smoothTrendLine, selectedDate: selectedDate)
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
            .background(adaptiveGreenBackground)
            .onAppear {
                loadMoodEntries()
            }
        }
        .background(getBackgroundColor())
    }
    
    private func getBackgroundColor() -> Color {
        switch selectedTheme {
        case "Dark":
            return Color.black
        case "Light":
            return adaptiveGreenBackground
        default:
            return Color(.systemBackground)
        }
    }
    
    private func changeDate(_ value: Int) {
        let calendar = Calendar.current
        let component: Calendar.Component
        
        switch selectedTimeRange {
        case .daily:
            component = .day
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        case .yearly:
            component = .year
        }
        
        if let newDate = calendar.date(byAdding: component, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func dateRangeString(from date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .daily:
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        case .weekly:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.end ?? date
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            
            // If same month, show "Jan 1 - 7, 2024"
            let startMonth = calendar.component(.month, from: startOfWeek)
            let endMonth = calendar.component(.month, from: endOfWeek)
            
            if startMonth == endMonth {
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "d"
                let yearFormatter = DateFormatter()
                yearFormatter.dateFormat = "yyyy"
                return "\(startString) - \(dayFormatter.string(from: endOfWeek)), \(yearFormatter.string(from: endOfWeek))"
            } else {
                formatter.dateFormat = "MMM d, yyyy"
                return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
            }
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .yearly:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }
    
    func loadMoodEntries() {
            guard let userID = authViewModel.userSession?.uid else {
                print("DEBUG: Cannot load analytics, user not logged in.")
                return
            }
            
            Task {
                do {
                    self.entries = try await DatabaseService.shared.fetchMoodEntries(forUserID: userID)
                } catch {
                    print("DEBUG: Failed to load analytics from Firestore: \(error)")
                }
        }
    }
}



// Calendar View Component
struct MoodCalendarView: View {
    let entries: [MoodEntry]
    @State private var selectedDate = Date()
    @State private var selectedMonth = Date()
    @Environment(\.colorScheme) var colorScheme
    
    private var calendar = Calendar.current
    
    // Adaptive green background
    private var adaptiveGreenBackground: Color {
        colorScheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }
    
    // PUBLIC initializer
    init(entries: [MoodEntry]) {
        self.entries = entries
    }
    
    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(monthYearString(from: selectedMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Weekday headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            moods: getMoodsForDate(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                        )
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            // Legend
            MoodLegendView()
                .padding()
            
            Spacer()
        }
        .background(adaptiveGreenBackground)
    }
    
    private var calendarDays: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date?] = []
        var currentDate = startOfWeek
        
        for _ in 0..<42 { // 6 weeks x 7 days
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func changeMonth(_ value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func getMoodsForDate(_ date: Date) -> [String] {
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }.map { $0.mainMood }
    }
}

// Individual calendar day view - Enhanced for multiple moods
struct CalendarDayView: View {
    let date: Date
    let moods: [String]
    let isCurrentMonth: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            // Background with multiple mood colors
            if moods.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 40)
            } else if moods.count == 1 {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.moodColor(for: moods[0]))
                    .frame(height: 40)
            } else {
                // Multiple moods - create segments
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                            Rectangle()
                                .fill(Color.moodColor(for: mood))
                                .frame(width: geometry.size.width / CGFloat(moods.count))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: 40)
            }
            
            // Border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
                .frame(height: 40)
            
            // Day number
            Text(dayNumber)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
                .opacity(isCurrentMonth ? 1.0 : 0.3)
        }
    }
    
    private var textColor: Color {
        guard !moods.isEmpty else {
            return .primary
        }
        
        // Use contrasting text color based on mood color intensity
        let darkMoods = ["Happy", "Calm", "Stressed", "Angry", "Tired", "Sick"]
        let hasDarkMood = moods.contains { darkMoods.contains($0) }
        
        if hasDarkMood {
            return colorScheme == .dark ? .white : .black
        } else {
            return .primary
        }
    }
}

// Mood legend component
struct MoodLegendView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let moods = [
        "Happy", "Calm", "Neutral", "Sad",
        "Stressed", "Angry", "Tired", "Sick"
    ]
    
    // Adaptive background for legend
    private var legendBackground: Color {
        colorScheme == .dark ? Color(.systemGray5).opacity(0.8) : Color(.systemGray6).opacity(0.9)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mood Colors")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(moods, id: \.self) { mood in
                    HStack {
                        Circle()
                            .fill(Color.moodColor(for: mood))
                            .frame(width: 12, height: 12)
                        Text(mood)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(legendBackground)
        .cornerRadius(12)
    }
}

// Chart View Component
struct MoodChartView: View {
    let entries: [MoodEntry]
    let timeRange: AnalyticsView.TimeRange
    let smoothLine: Bool
    let selectedDate: Date // Changed from selectedMonth to selectedDate
    @Environment(\.colorScheme) var colorScheme
    
    // Adaptive green background
    private var adaptiveGreenBackground: Color {
        colorScheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mood frequency chart
                MoodFrequencyChart(entries: filteredEntries)
                
                // Mood trend over time
                MoodTrendChart(entries: filteredEntries, timeRange: timeRange, smoothLine: smoothLine)
                
                // Statistics
                MoodStatisticsView(entries: filteredEntries)
            }
            .padding()
        }
        .background(adaptiveGreenBackground)

    }
    
    private var filteredEntries: [MoodEntry] {
        let calendar = Calendar.current
        
        switch timeRange {
        case .daily:
            return entries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        case .weekly:
            // Get the week interval for the selected date
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
                return []
            }
            return entries.filter {
                $0.date >= weekInterval.start && $0.date < weekInterval.end
            }
        case .monthly:
            return entries.filter { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
        case .yearly:
            return entries.filter { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .year) }
        }
    }
}

// Mood frequency bar chart
struct MoodFrequencyChart: View {
    let entries: [MoodEntry]
    @Environment(\.colorScheme) var colorScheme
    
    // Adaptive background for chart containers
    private var chartBackground: Color {
        colorScheme == .dark ? Color(.systemGray5).opacity(0.8) : Color(.systemGray6).opacity(0.9)
    }
    
    private var moodCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for entry in entries {
            counts[entry.mainMood, default: 0] += 1
        }
        return counts
    }
    
    private var maxCount: Int {
        moodCounts.values.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mood Frequency")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom)
            
            if entries.isEmpty {
                Text("No data for selected period")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(moodCounts.sorted(by: { $0.value > $1.value }), id: \.key) { mood, count in
                        HStack {
                            Text(mood)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(width: 60, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack {
                                    Rectangle()
                                        .fill(Color.chartMoodColor(for: mood))
                                        .frame(width: CGFloat(count) / CGFloat(maxCount) * geometry.size.width)
                                        .animation(.easeInOut, value: count)
                                    Spacer()
                                }
                            }
                            .frame(height: 20)
                            
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(chartBackground)
        .cornerRadius(12)
    }
}

// Enhanced mood trend visualization with axes and smoothing
struct MoodTrendChart: View {
    let entries: [MoodEntry]
    let timeRange: AnalyticsView.TimeRange
    let smoothLine: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Adaptive background for chart containers
    private var chartBackground: Color {
        colorScheme == .dark ? Color(.systemGray5).opacity(0.8) : Color(.systemGray6).opacity(0.9)
    }
    
    private var moodValues: [(Date, Double)] {
        let moodScores: [String: Double] = [
            "Happy": 5.0,
            "Calm": 4.0,
            "Neutral": 3.0,
            "Tired": 2.5,
            "Stressed": 2.0,
            "Sad": 1.5,
            "Angry": 1.0,
            "Sick": 0.5
        ]
        
        return entries.compactMap { entry in
            if let score = moodScores[entry.mainMood] {
                return (entry.date, score)
            }
            return nil
        }.sorted { $0.0 < $1.0 }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch timeRange {
        case .daily:
            formatter.dateFormat = "HH:mm"
        case .weekly:
            formatter.dateFormat = "E"
        case .monthly:
            formatter.dateFormat = "M/d"
        case .yearly:
            formatter.dateFormat = "MMM"
        }
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mood Trend")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom)
            
            if moodValues.isEmpty {
                Text("No data for trend analysis")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 0) {
                    // Chart area with Y-axis labels
                    HStack(spacing: 0) {
                        // Y-axis labels
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach([5, 4, 3, 2, 1], id: \.self) { score in
                                Text("\(score)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(height: 30)
                                if score > 1 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(width: 20)
                        
                        // Chart area
                        GeometryReader { geometry in
                            ZStack {
                                // Grid lines - FIXED: Use named parameter instead of _
                                VStack(spacing: 0) {
                                    ForEach(0..<5) { index in
                                        Rectangle()
                                            .fill(Color(.systemGray4))
                                            .frame(height: 0.5)
                                        if index < 4 {
                                            Spacer()
                                        }
                                    }
                                }
                                
                                // Trend line
                                if smoothLine {
                                    SmoothTrendLine(moodValues: moodValues, geometry: geometry)
                                } else {
                                    SharpTrendLine(moodValues: moodValues, geometry: geometry)
                                }
                                
                                // Data points
                                let moodArray = Array(moodValues.enumerated())
                                ForEach(moodArray, id: \.offset) { index, moodData in
                                    let (_, value) = moodData
                                    let x = CGFloat(index) * (geometry.size.width / CGFloat(max(moodValues.count - 1, 1)))
                                    let y = geometry.size.height - ((value - 0.5) / 4.5) * geometry.size.height
                                    
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 6, height: 6)
                                        .position(x: x, y: y)
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                    
                    // X-axis labels
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20)
                        
                        HStack {
                            ForEach(Array(moodValues.enumerated()), id: \.offset) { index, moodData in
                                let (date, _) = moodData
                                if index == 0 || index == moodValues.count - 1 || (index % max(1, moodValues.count / 4) == 0) {
                                    Text(dateFormatter.string(from: date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                
                // Y-axis label
                HStack {
                    Spacer()
                    Text("Mood Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(chartBackground)
        .cornerRadius(12)
    }
}

// Sharp trend line component
struct SharpTrendLine: View {
    let moodValues: [(Date, Double)]
    let geometry: GeometryProxy
    
    var body: some View {
        Path { path in
            guard !moodValues.isEmpty else { return }
            
            let maxY = geometry.size.height
            let stepX = geometry.size.width / CGFloat(max(moodValues.count - 1, 1))
            
            for (index, (_, value)) in moodValues.enumerated() {
                let x = CGFloat(index) * stepX
                let y = maxY - ((value - 0.5) / 4.5) * maxY
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(Color.accentColor, lineWidth: 2)
    }
}

// Smooth trend line component
struct SmoothTrendLine: View {
    let moodValues: [(Date, Double)]
    let geometry: GeometryProxy
    
    var body: some View {
        Path { path in
            guard moodValues.count > 1 else { return }
            
            let maxY = geometry.size.height
            let stepX = geometry.size.width / CGFloat(max(moodValues.count - 1, 1))
            
            let points = moodValues.enumerated().map { index, moodData in
                let (_, value) = moodData
                let x = CGFloat(index) * stepX
                let y = maxY - ((value - 0.5) / 4.5) * maxY
                return CGPoint(x: x, y: y)
            }
            
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i-1]
                
                let controlPoint1 = CGPoint(
                    x: previous.x + (current.x - previous.x) * 0.3,
                    y: previous.y
                )
                let controlPoint2 = CGPoint(
                    x: current.x - (current.x - previous.x) * 0.3,
                    y: current.y
                )
                
                path.addCurve(to: current, control1: controlPoint1, control2: controlPoint2)
            }
        }
        .stroke(Color.accentColor, lineWidth: 2)
    }
}

// Statistics view
struct MoodStatisticsView: View {
    let entries: [MoodEntry]
    @Environment(\.colorScheme) var colorScheme
    
    // Adaptive background for statistics
    private var statsBackground: Color {
        colorScheme == .dark ? Color(.systemGray5).opacity(0.8) : Color(.systemGray6).opacity(0.9)
    }
    
    private var mostCommonMood: String {
        let moodCounts = entries.reduce(into: [String: Int]()) { counts, entry in
            counts[entry.mainMood, default: 0] += 1
        }
        return moodCounts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private var averageMoodScore: Double {
        let moodScores: [String: Double] = [
            "Happy": 5.0, "Calm": 4.0, "Neutral": 3.0, "Tired": 2.5,
            "Stressed": 2.0, "Sad": 1.5, "Angry": 1.0, "Sick": 0.5
        ]
        
        let scores = entries.compactMap { moodScores[$0.mainMood] }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entries.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Most Common")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(mostCommonMood)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Avg. Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f/5", averageMoodScore))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(statsBackground)
        .cornerRadius(12)
    }
}
