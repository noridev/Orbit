//
//  ProfileEditView.swift
//  Orbit
//
//  Created by makinosp on 2024/08/21.
//

import AsyncSwiftUI
import VRCKit

struct ProfileEditView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?
    @State private var profileEditVM: ProfileEditViewModel
    @State private var isPresentedLanguagePicker = false
    @State private var isRequesting = false
    @State private var selectedLanguage: LanguageTag?
    @State private var inputtedURL: URL?

    init(user: User) {
        profileEditVM = ProfileEditViewModel(user: user)
    }

    var body: some View {
        NavigationStack {
            Form {
                statusSection
                pronounsSection
                descriptionSection
                languageSection
                bioLinksSection
            }
            .toolbar { toolbarContents }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await _ = appVM.login()
        }
        .sheet(isPresented: $isPresentedLanguagePicker) {
            LanguagePickerView(selectedLanguage: $selectedLanguage)
                .presentationDetents([.medium])
        }
        .onChange(of: selectedLanguage) {
            if let selectedLanguage = selectedLanguage,
               !profileEditVM.editingUserInfo.tags.languageTags.contains(selectedLanguage) {
                profileEditVM.editingUserInfo.tags.languageTags.append(selectedLanguage)
                self.selectedLanguage = nil
            }
        }
        .onChange(of: inputtedURL) {
            guard let inputtedURL = inputtedURL else { return }
            profileEditVM.editingUserInfo.bioLinks.append(inputtedURL)
            self.inputtedURL = nil
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker(selection: $profileEditVM.editingUserInfo.status) {
                ForEach(UserStatus.allCases) { status in
                    Text(status.description).tag(status)
                }
            } label: {
                Label {
                    Text("Status")
                } icon: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(profileEditVM.editingUserInfo.status.color)
                }
            }
            TextField(
                "Status Description",
                text: $profileEditVM.editingUserInfo.statusDescription
            )
        }
    }
    
    private var pronounsSection: some View {
        Section("Pronouns") {
            TextField("Pronouns (e.g., they/them, she/her)", text: Binding(
                get: { profileEditVM.editingUserInfo.pronouns ?? "" },
                set: { profileEditVM.editingUserInfo.pronouns = $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private var descriptionSection: some View {
        Section("Description") {
            TextEditor(text: $profileEditVM.editingUserInfo.bio)
        }
    }

    private var languageSection: some View {
        Section("Language") {
            ForEach(profileEditVM.editingUserInfo.tags.languageTags) { tag in
                Text(tag.description)
                    .swipeActions {
                        Button(role: .destructive) {
                            profileEditVM.removeTag(tag)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }
            
            if profileEditVM.canAddMoreLanguages {
                Button {
                    isPresentedLanguagePicker = true
                } label: {
                    Label {
                        Text("Add")
                    } icon: {
                        IconSet.plusCircleFilled.icon.symbolRenderingMode(.multicolor)
                    }
                }
            }
        }
    }

    private var bioLinksSection: some View {
        Section("Social Links") {
            ForEach(Array(profileEditVM.tempBioLinks.enumerated()), id: \.offset) { index, url in
                HStack {
                    IconSet.link.icon
                        .foregroundStyle(.gray)
                    TextField("Enter URL", text: Binding(
                        get: { url },
                        set: { newValue in
                            if index < profileEditVM.tempBioLinks.count {
                                profileEditVM.tempBioLinks[index] = newValue
                            }
                        }
                    ))
                    .focused($focusedField, equals: index)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if focusedField == index {
                                focusedField = nil
                            }
                            profileEditVM.removeUrl(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            
            if profileEditVM.canAddMoreLinks {
                Button {
                    let newIndex = profileEditVM.tempBioLinks.count
                    profileEditVM.tempBioLinks.append("")
                    focusedField = newIndex
                } label: {
                    Label {
                        Text("Add")
                    } icon: {
                        IconSet.plusCircleFilled.icon.symbolRenderingMode(.multicolor)
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder private var toolbarContents: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
        ToolbarItem {
            AsyncButton {
                await saveProfileAction()
            } label: {
                if isRequesting {
                    ProgressView()
                } else {
                    Text("Save")
                }
            }
            .disabled(isRequesting)
        }
    }

    private func saveProfileAction() async {
        defer {
            isRequesting = false
            dismiss()
        }
        isRequesting = true
        do {
            guard let user = appVM.user else { throw ApplicationError.userIsNotSetError }
            try await profileEditVM.saveProfile(service: appVM.services.userService)
            print("✅ [saveProfileAction] Profile saved to server successfully")
            
            let updatedUser = User(user: user, editedUserInfo: profileEditVM.editingUserInfo)
            appVM.user = updatedUser
            print("✅ [saveProfileAction] AppViewModel user updated locally")
            print("🔄 [saveProfileAction] Updated status: \(updatedUser.status.description)")
            print("🔄 [saveProfileAction] Updated pronouns: \(updatedUser.pronouns ?? "nil")")
            print("🔄 [saveProfileAction] Updated bio: \(updatedUser.bio ?? "nil")")
            
            NotificationCenter.default.post(name: .profileUpdated, object: updatedUser)
            print("🔔 [saveProfileAction] Profile update notification sent")
        } catch {
            print("❌ [saveProfileAction] Error saving profile: \(error)")
            appVM.handleError(error)
        }
    }
}
