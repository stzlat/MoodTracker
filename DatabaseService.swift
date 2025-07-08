// File: DatabaseService.swift
//

import Foundation
import FirebaseFirestore

class DatabaseService {
    
    static let shared = DatabaseService()
    private init() {}
    
    private let db = Firestore.firestore()
    private var moodEntriesCollection: CollectionReference {
        return db.collection("mood_entries")
    }
    
    // Save a mood entry for a specific user
    func saveMoodEntry(_ entry: MoodEntry, forUserID userID: String) async throws {
        // Create a new document in the "mood_entries" collection
        let document = moodEntriesCollection.document()
        
        // Add the userID to the entry before saving
        var entryWithUserID = entry
        entryWithUserID.userID = userID
        
        // Use Codable support to save the object
        try document.setData(from: entryWithUserID)
        print("DEBUG: Mood entry saved to Firestore for user \(userID)")
    }
    
    // Fetch all mood entries for a specific user
    // DatabaseService.swift

    func fetchMoodEntries(forUserID userID: String) async throws -> [MoodEntry] {
        let snapshot = try await moodEntriesCollection
            .whereField("userID", isEqualTo: userID)
            .order(by: "date", descending: true)
            .getDocuments()
            
        // --- 从这里开始修改 ---

        var decodedEntries: [MoodEntry] = []
        print("DEBUG: Found \(snapshot.documents.count) documents for user. Attempting to decode...")

        for document in snapshot.documents {
            do {
                // 尝试将文档解码为 MoodEntry
                var entry = try document.data(as: MoodEntry.self)
                entry.firestoreID = document.documentID
                decodedEntries.append(entry)
                print("  ✅ Successfully decoded document: \(document.documentID)")
            } catch {
                // 如果解码失败，打印详细的错误信息
                print("  ❌ DECODING FAILED for document: \(document.documentID)")
                print("     Error: \(error)") // 这行会告诉我们具体是哪个字段出了问题
                print("     Document data: \(document.data())") // 这行会打印出原始数据供对比
                print("---------------------------------")
            }
        }
        
        print("DEBUG: Finished decoding. Total successful entries: \(decodedEntries.count)")
        return decodedEntries
        
        // --- 修改到这里结束 ---
    }
    
    // Get total entry count for a user
    func getTotalEntriesCount(forUserID userID: String) async -> Int {
        do {
            let snapshot = try await moodEntriesCollection
                .whereField("userID", isEqualTo: userID)
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("DEBUG: Could not get total entries count: \(error)")
            return 0
        }
    }

    // Clear all data for a user
    func clearAllData(forUserID userID: String) async {
        do {
            let snapshot = try await moodEntriesCollection.whereField("userID", isEqualTo: userID).getDocuments()
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            print("DEBUG: All data cleared for user \(userID)")
        } catch {
            print("DEBUG: Error clearing data: \(error)")
        }
    }
}//
//  DatabaseService.swift
//  MoodTracker
//
//  Created by 吴青峰的老婆 on 2025/7/7.
//

