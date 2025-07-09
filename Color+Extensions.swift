//
//  File: Color+Extensions.swift
//  MoodTracker
//
//  Created by YourName on 7/7/25.
//

import SwiftUI

// 在这里统一定义所有对 Color 的扩展
extension Color {
    static func moodColor(for mood: String, opacity: Double = 0.7) -> Color {
        switch mood {
        case "Happy": return .green.opacity(opacity)
        case "Calm": return .blue.opacity(opacity)
        case "Neutral": return Color(.systemGray).opacity(opacity)
        case "Sad": return Color(.systemBlue).opacity(opacity + 0.1)
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
        case "Neutral": return Color(.systemGray)
        case "Sad": return Color(.systemBlue)
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
//  Color+Extensions.swift
//  MoodTracker
//
//

