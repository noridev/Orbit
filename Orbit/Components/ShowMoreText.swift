//
//  ShowMoreText.swift
//  Orbit
//
//  Created by makinosp on 2024/10/12.
//

import MemberwiseInit
import SwiftUI
import Translation

@MemberwiseInit
struct ShowMoreText: View {
    @State private var isExpanded = false
    @State private var translatedText: String?
    @State private var showTranslation = false
    @State private var translationConfiguration: Any?
    @State private var translationTrigger = UUID()
    @Init(.internal, label: "_") private let text: String
    @Init(.internal, default: 3) private let lineLimit: Int

    var body: some View {
        VStack(spacing: 3) {
            Text(displayText)
                .lineLimit(isExpanded ? nil : lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .translationPresentation(isPresented: $showTranslation, text: text) { translatedText in
                    Task { @MainActor in
                        self.translatedText = translatedText
                    }
                }
            
            Spacer()
            
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    if #available(iOS 18.0, *) {
                        // iOS 18+: translationTask
                        if translatedText != nil {
                            Button {
                                withAnimation {
                                    translatedText = nil
                                    translationConfiguration = nil
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Original")
                                }
                                .fontWeight(.regular)
                            }
                        } else {
                            Button {
                                withAnimation {
                                    translationTrigger = UUID()
                                    translationConfiguration = TranslationSession.Configuration()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "translate")
                                    Text("Translate")
                                }
                                .fontWeight(.regular)
                            }
                        }
                    } else {
                        // iOS 17.4+: translationPresentation
                        if translatedText != nil {
                            Button {
                                withAnimation {
                                    translatedText = nil
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Original")
                                }
                                .fontWeight(.regular)
                            }
                        } else {
                            Button {
                                Task { @MainActor in
                                    showTranslation = true
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "translate")
                                    Text("Translate")
                                }
                                .fontWeight(.regular)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation { isExpanded.toggle() }
                    } label: {
                        Text(isExpanded ? "Show less" : "Show more")
                            .fontWeight(.regular)
                    }
                }
            }
        }
        .background(
            Group {
                if #available(iOS 18.0, *) {
                    TranslationTaskView(
                        configuration: translationConfiguration as? TranslationSession.Configuration,
                        text: text,
                        trigger: translationTrigger,
                        onTranslation: { translatedText in
                            Task { @MainActor in
                                withAnimation {
                                    self.translatedText = translatedText
                                }
                            }
                        },
                        onError: {
                            Task { @MainActor in
                                showTranslation = true
                            }
                        }
                    )
                }
            }
        )
    }
    
    private var displayText: String {
        translatedText ?? text
    }
}

@available(iOS 18.0, *)
struct TranslationTaskView: View {
    let configuration: TranslationSession.Configuration?
    let text: String
    let trigger: UUID
    let onTranslation: @Sendable (String) -> Void
    let onError: @Sendable () -> Void
    
    var body: some View {
        Color.clear
            .translationTask(configuration) { @Sendable session in
                do {
                    let response = try await session.translate(text)
                    await MainActor.run {
                        onTranslation(response.targetText)
                    }
                } catch {
                    await MainActor.run {
                        onError()
                    }
                }
            }
            .id(trigger)
    }
}
