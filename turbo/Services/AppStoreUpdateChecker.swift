//
//  AppStoreUpdateChecker.swift
//  turbo
//
//  Created on 2025-01-XX.
//

import Foundation
import UIKit
import Combine

@MainActor
class AppStoreUpdateChecker: ObservableObject {
    @Published var showUpdateAlert = false
    @Published var appStoreVersion: String?
    
    private var appStoreURL: String?
    
    // Set to true to test the update alert without checking the App Store
    // Remember to set this back to false before releasing!
    private let testMode = false
    
    func checkForUpdates() {
        // Test mode: show alert immediately
        if testMode {
            self.appStoreVersion = "1.3.0"
            self.showUpdateAlert = true
            return
        }
        
        guard let bundleId = Bundle.main.bundleIdentifier else {
            print("Could not get bundle identifier")
            return
        }
        
        // iTunes API endpoint
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            print("Invalid URL")
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let storeVersion = firstResult["version"] as? String {
                    
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    
                    // Compare versions
                    if isVersionNewer(storeVersion, than: currentVersion) {
                        // Get App Store URL from the API response
                        let trackViewUrl = firstResult["trackViewUrl"] as? String
                        
                        await MainActor.run {
                            self.appStoreVersion = storeVersion
                            self.appStoreURL = trackViewUrl
                            self.showUpdateAlert = true
                        }
                    }
                }
            } catch {
                // Silently fail - don't interrupt user experience if check fails
                print("Update check failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func isVersionNewer(_ version1: String, than version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1 = i < v1Components.count ? v1Components[i] : 0
            let v2 = i < v2Components.count ? v2Components[i] : 0
            
            if v1 > v2 {
                return true
            } else if v1 < v2 {
                return false
            }
        }
        
        return false
    }
    
    func openAppStore() {
        // Use the App Store URL from the API response, or construct from bundle ID
        let urlString: String
        if let storedURL = appStoreURL {
            urlString = storedURL
        } else if let bundleId = Bundle.main.bundleIdentifier {
            // Fallback: construct URL from bundle ID
            urlString = "https://apps.apple.com/app/bundleId/\(bundleId)"
        } else {
            return
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
