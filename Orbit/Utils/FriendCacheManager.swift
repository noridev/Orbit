//
//  FriendCacheManager.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import Foundation
import VRCKit

struct FriendCacheManager {
    private static var cacheURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent("friendCache.json")
    }

    static func saveFriends(_ friends: [Friend]) {
        guard let url = cacheURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)
            print("--- Saving Cache ---")
            let data = try encoder.encode(friends)
            print("Attempting to save \(data.count) bytes to friendCache.json")
            try data.write(to: url, options: .atomic)
            print("Save successful.")
            print("--------------------")
        } catch {
            print("Error saving friend cache to file: \(error)")
        }
    }

    static func loadFriends() throws -> [Friend] {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        
        guard let rawString = String(data: data, encoding: .utf8) else {
            print("Could not convert data to UTF-8 string.")
            return try JSONDecoder().decode([Friend].self, from: data)
        }
        
        let sanitizedString = rawString.filter { character in
            guard let firstScalar = character.unicodeScalars.first else { return false }
            let controlRanges = [0x00...0x1F, 0x7F...0x9F]
            return !controlRanges.contains(where: { $0.contains(Int(firstScalar.value)) })
        }

        if let sanitizedData = sanitizedString.data(using: .utf8) {
            return try JSONDecoder().decode([Friend].self, from: sanitizedData)
        }
        
        return try JSONDecoder().decode([Friend].self, from: data)
    }
    
    static func deleteCache() {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
            print("Cache file deleted successfully.")
        } catch {
            print("Error deleting cache file: \(error)")
        }
    }
    
    static func loadRawData() -> String? {
        guard let url = cacheURL, let data = try? Data(contentsOf: url) else {
            return nil
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }

        return String(data: data, encoding: .utf8)
    }
}
