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
    @Init(.internal, label: "text") private let text: String
    @Init(.internal, default: 3) private let lineLimit: Int
    @Init(.internal, default: nil) private let onToggle: ((Bool) -> Void)?
    @Init(.internal, default: nil) private let scrollProxy: ScrollViewProxy?
    @Init(.internal, default: nil) private let scrollTargetId: String?

    @State private var isTruncated: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ZStack(alignment: .topLeading) {
                Text(displayText)
                    .lineLimit(isExpanded ? nil : lineLimit)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Text(displayText)
                            .font(.body)
                            .lineLimit(lineLimit)
                            .background(GeometryReader { proxy in
                                Color.clear.preference(key: TextHeightPreferenceKey.self, value: proxy.size.height)
                            })
                            .hidden()
                    )
                    .onPreferenceChange(TextHeightPreferenceKey.self) { limitedHeight in
                        let fullHeight = textHeight(for: displayText, lineLimit: nil)
                        let limited = textHeight(for: displayText, lineLimit: lineLimit)
                        isTruncated = fullHeight > limited + 1
                    }
                    .translationPresentation(isPresented: $showTranslation, text: text) { translatedText in
                        Task { @MainActor in
                            self.translatedText = translatedText
                        }
                    }
            }
            Spacer()
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isTruncated {
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
                                .font(.footnote)
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
                                .font(.footnote)
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
                                .font(.footnote)
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
                                .font(.footnote)
                                .fontWeight(.regular)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation { 
                            isExpanded.toggle()
                            onToggle?(isExpanded)
                            if !isExpanded, let scrollProxy = scrollProxy, let scrollTargetId = scrollTargetId {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scrollProxy.scrollTo(scrollTargetId, anchor: .top)
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.footnote)
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

    private func textHeight(for text: String, lineLimit: Int?) -> CGFloat {
        let label = UILabel()
        label.numberOfLines = lineLimit ?? 0
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.lineBreakMode = .byWordWrapping
        let maxSize = CGSize(width: UIScreen.main.bounds.width - 48, height: CGFloat.greatestFiniteMagnitude)
        let size = label.sizeThatFits(maxSize)
        return size.height
    }

    private struct TextHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
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
