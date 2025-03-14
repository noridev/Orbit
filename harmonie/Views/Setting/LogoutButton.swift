//
//  LogoutButton.swift
//  Harmonie
//
//  Created by makinosp on 2024/10/12.
//

import SwiftUI

struct LogoutButton: View {
    @Environment(AppViewModel.self) var appVM
    @State private var isPresentedAlert = false

    var body: some View {
        Button("Logout", systemImage: IconSet.logout.systemName, role: .destructive) {
            isPresentedAlert.toggle()
        }
        .alert("Logout", isPresented: $isPresentedAlert) {
            Button("Logout", role: .destructive) {
                Task { await appVM.logout() }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}
