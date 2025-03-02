//
//  OrbitApp.swift
//  Orbit
//
//  Created by makinosp on 2024/03/03.
//

import SwiftUI

@main
struct OrbitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppViewModel())
                .environment(FriendViewModel())
                .environment(FavoriteViewModel())
        }
    }
}
