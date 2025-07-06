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
            let data = try JSONEncoder().encode(friends)
            print("--- Saving Cache ---")
            print("Attempting to save \(data.count) bytes to friendCache.json")
            try data.write(to: url, options: .atomic)
            print("Save successful.")
            print("--------------------")
        } catch {
            print("Error saving friend cache to file: \(error)")
        }
    }

    static func loadFriends() -> [Friend] {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        do {
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

            print("--- Loading Cache ---")
            print("friendCache.json file found. Sanitized Content:")
            print(sanitizedString)
            print("---------------------")

            if let sanitizedData = sanitizedString.data(using: .utf8) {
                return try JSONDecoder().decode([Friend].self, from: sanitizedData)
            }
            
            return try JSONDecoder().decode([Friend].self, from: data)
        } catch {
            print("Error loading/decoding cache. Deleting corrupted file. Error: \(error)")
            try? FileManager.default.removeItem(at: url)
            return []
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
