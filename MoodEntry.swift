//  MoodEntry.swift
//

import Foundation

struct MoodEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let mainMood: String
    let subMood: String?
    let notes: String?
}
