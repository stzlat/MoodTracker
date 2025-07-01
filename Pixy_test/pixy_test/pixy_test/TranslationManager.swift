import Foundation

class TranslationManager {
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let baseLanguage = "en"
    private let translationsDirectory = "Locales"
    
    // MARK: - Public Methods
    
    /// Main function to generate missing translations
    func generateMissingTranslations() {
        let locales = loadAllLocales()
        let missingKeys = findMissingKeys(comparedToBase: locales["en"] ?? [:], locales: locales)
        
        // In production, replace with actual Google Translate API calls
        let mockTranslations = generateMockTranslations(for: missingKeys)
        
        saveTranslations(mockTranslations, to: locales)
    }
    
    /// Function to remove specified keys (equivalent to remove-translation-keys.js)
    func removeTranslationKeys(_ keysToRemove: [String]) {
        var locales = loadAllLocales()
        
        for (language, _) in locales {
            for key in keysToRemove {
                locales[language]?.removeValue(forKey: key)
            }
        }
        
        saveAllLocales(locales)
    }
    
    // MARK: - Private Methods
    
    private func loadAllLocales() -> [String: [String: String]] {
        var locales: [String: [String: String]] = [:]
        let bundleURL = Bundle.main.bundleURL
        let directoryURL = bundleURL.appendingPathComponent(translationsDirectory)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            
            for file in files {
                let language = file.deletingPathExtension().lastPathComponent
                if let data = try? Data(contentsOf: file),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    locales[language] = json
                }
            }
        } catch {
            print("Error loading locales: \(error)")
        }
        
        return locales
    }
    
    private func findMissingKeys(comparedToBase base: [String: String], locales: [String: [String: String]]) -> [String: [String]] {
        var missingKeys: [String: [String]] = [:]
        
        for (language, translations) in locales {
            if language == baseLanguage { continue }
            
            let missing = base.keys.filter { !translations.keys.contains($0) }
            if !missing.isEmpty {
                missingKeys[language] = missing
            }
        }
        
        return missingKeys
    }
    
    private func generateMockTranslations(for missingKeys: [String: [String]]) -> [String: [String: String]] {
        // In production, replace with Google Translate API calls
        var translations: [String: [String: String]] = [:]
        
        guard let baseTranslations = loadAllLocales()["en"] else {
            return translations
        }
        
        for (language, keys) in missingKeys {
            translations[language] = [:]
            for key in keys {
                translations[language]?[key] = "[\(language)] \(baseTranslations[key] ?? "")"
            }
        }
        
        return translations
    }
    
    private func saveTranslations(_ newTranslations: [String: [String: String]], to existingLocales: [String: [String: String]]) {
        var allLocales = existingLocales
        
        for (language, translations) in newTranslations {
            allLocales[language]?.merge(translations) { (_, new) in new }
        }
        
        saveAllLocales(allLocales)
    }
    
    private func saveAllLocales(_ locales: [String: [String: String]]) {
        let bundleURL = Bundle.main.bundleURL
        let directoryURL = bundleURL.appendingPathComponent(translationsDirectory)
        
        for (language, translations) in locales {
            let fileURL = directoryURL.appendingPathComponent("\(language).json")
            
            do {
                let data = try JSONSerialization.data(withJSONObject: translations, options: [.prettyPrinted, .sortedKeys])
                try data.write(to: fileURL)
                print("Saved translations for \(language)")
            } catch {
                print("Error saving \(language): \(error)")
            }
        }
    }
}//
//  Untitled.swift
//  pixy_test
//
//  Created by Lone Shinoda on 2025-06-30.
//

