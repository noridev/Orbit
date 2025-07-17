//
//  UserDetailView+NoteSection.swift
//  Orbit
//
//  Created by makinosp on 2024/09/06.
//

import SwiftUI
import VRCKit

extension UserDetailView {
    var noteSection: some View {
        GroupBox("Note") {
            VStack(alignment: .leading) {
                if user.note.isEmpty {
                    Text("No note added")
                        .foregroundStyle(.gray)
                } else {
                    Text(user.note)
                        .font(.body)
                }
                Spacer()
                Button("Edit") {
                    isPresentedNoteEditor = true
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .groupBoxStyle(.card)
        .sheet(isPresented: $isPresentedNoteEditor) {
            NoteEditView(initialValue: user.note, userId: user.id) { text in
            }
            .presentationDetents([.small])
        }
    }
}
