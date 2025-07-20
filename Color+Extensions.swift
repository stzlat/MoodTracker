//  File: Color+Extensions.swift

import SwiftUI

extension Color {
    static func moodColor(for mood: String, opacity: Double = 0.7) -> Color {
        switch mood {
        case "Happy": return .green.opacity(opacity)
        case "Calm": return .blue.opacity(opacity)
        case "Neutral": return Color(red: 0.96, green: 0.87, blue: 0.70).opacity(opacity)
        case "Sad": return .gray.opacity(opacity)
        case "Stressed": return .orange.opacity(opacity)
        case "Angry": return .red.opacity(opacity)
        case "Tired": return .purple.opacity(opacity - 0.1)
        case "Sick": return .brown.opacity(opacity - 0.1)
        default: return Color(.systemGray3).opacity(opacity)
        }
    }
    
    static func chartMoodColor(for mood: String) -> Color {
        switch mood {
        case "Happy": return .green
        case "Calm": return .blue
        case "Neutral": return Color(red: 0.96, green: 0.87, blue: 0.70)
        case "Sad": return .gray 
        case "Stressed": return .orange
        case "Angry": return .red
        case "Tired": return .purple
        case "Sick": return .brown
        default: return Color(.systemGray)
        }
    }
    
    static var adaptiveGreenBackground: Color {
        return Color.green.opacity(0.1)
    }
}

