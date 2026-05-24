import SwiftUI
import PhotosUI

/// Final review screen — edit parsed fields, link LinkedIn, add photo, save.
struct ContactPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State var contact: ParsedContact
    let cardImage: UIImage

    @State private var saveState: SaveState = .idle
    @State private var contactPhotoItem: PhotosPickerItem? = nil
    @State private var showLinkedInSheet = false
    @Namespace private var glassNamespace

    enum SaveState: Equatable { case idle, saving, saved, error(String) }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.18),
                    Color(red: 0.10, green: 0.04, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // ── Avatar + Name header ────────────────────────────────
                    GlassEffectContainer(spacing: 0) {
                        VStack(spacing: 16) {
                            // Photo circle
                            ZStack {
                                if let photo = contact.photo {
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.6), .cyan.opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text(contact.initials.isEmpty ? "?" : contact.initials)
                                        .font(.system(size: 36, weight: .black))
                                        .foregroundColor(.white)
                                }

                                // Camera overlay for picking photo
                                PhotosPicker(selection: $contactPhotoItem, matching: .images) {
                                    ZStack {
                                        Circle()
                                            .fill(.black.opacity(0.3))
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 30, height: 30)
                                .offset(x: 30, y: 30)
                            }
                            .frame(width: 90, height: 90)

                            Text(contact.fullName.isEmpty ? "New Contact" : contact.fullName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            if !contact.jobTitle.isEmpty || !contact.company.isEmpty {
                                Text([contact.jobTitle, contact.company]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: " • "))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(28)
                    }
                    .padding(.horizontal, 20)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 24))
                    .glassEffectID("header", in: glassNamespace)

                    // ── Editable Fields ─────────────────────────────────────
                    GlassEffectContainer(spacing: 0) {
                        VStack(spacing: 0) {
                            fieldRow(icon: "person.fill",     label: "First Name",  binding: $contact.firstName)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "person.fill",     label: "Last Name",   binding: $contact.lastName)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "briefcase.fill",  label: "Job Title",   binding: $contact.jobTitle)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "building.2.fill", label: "Company",     binding: $contact.company)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "envelope.fill",   label: "Email",       binding: emailBinding)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "phone.fill",      label: "Phone",       binding: phoneBinding)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "globe",           label: "Website",     binding: $contact.website)
                            Divider().background(.white.opacity(0.1))
                            fieldRow(icon: "map.fill",        label: "Address",     binding: $contact.address)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 20)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                    .glassEffectID("fields", in: glassNamespace)

                    // ── LinkedIn ────────────────────────────────────────────
                    GlassEffectContainer(spacing: 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.crop.square.filled.and.at.rectangle")
                                    .foregroundColor(.blue)
                                    .frame(width: 28)
                                Text("LinkedIn")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            if contact.linkedinUrl.isEmpty {
                                HStack(spacing: 12) {
                                    // Search button
                                    Button {
                                        openLinkedInSearch()
                                    } label: {
                                        Label("Search LinkedIn", systemImage: "magnifyingglass")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                    }
                                    .glassEffect(in: Capsule())
                                    .tint(.blue.opacity(0.4))

                                    // Paste URL button
                                    Button {
                                        showLinkedInSheet = true
                                    } label: {
                                        Label("Paste URL", systemImage: "link")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                    }
                                    .glassEffect(in: Capsule())
                                }
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(contact.linkedinUrl)
                                        .font(.system(size: 13))
                                        .foregroundColor(.cyan)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        contact.linkedinUrl = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                    .glassEffectID("linkedin", in: glassNamespace)

                    // ── Notes ───────────────────────────────────────────────
                    GlassEffectContainer(spacing: 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.yellow)
                                    .frame(width: 28)
                                Text("Notes")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            TextField("Where did you meet? (Optional)", text: $contact.notes, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .tint(.cyan)
                                .lineLimit(3...6)
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                    .glassEffectID("notes", in: glassNamespace)

                    // ── Save Button ──────────────────────────────────────────
                    saveButton

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Review Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showLinkedInSheet) {
            LinkedInPasteSheet(linkedinUrl: $contact.linkedinUrl)
        }
        .onChange(of: contactPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    contact.photo = image
                }
            }
        }
    }

    // MARK: - Field Row
    private func fieldRow(icon: String, label: String, binding: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField(label, text: binding)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .tint(.cyan)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Save Button
    @ViewBuilder
    private var saveButton: some View {
        Button {
            saveContact()
        } label: {
            Group {
                switch saveState {
                case .idle:
                    Label("Save to Contacts", systemImage: "person.badge.plus")
                        .font(.system(size: 17, weight: .bold))
                case .saving:
                    HStack {
                        ProgressView().tint(.white)
                        Text("Saving...")
                    }
                    .font(.system(size: 17, weight: .bold))
                case .saved:
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                case .error(let msg):
                    Label(msg, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .tint(.purple.opacity(0.4))
        .padding(.horizontal, 20)
        .disabled(saveState == .saving)
        .animation(.spring(duration: 0.4), value: saveState == .saving)
    }

    // MARK: - Helpers
    private var emailBinding: Binding<String> {
        Binding(
            get: { contact.emails.first ?? "" },
            set: { contact.emails = [$0].filter { !$0.isEmpty } }
        )
    }

    private var phoneBinding: Binding<String> {
        Binding(
            get: { contact.phones.first ?? "" },
            set: { contact.phones = [$0].filter { !$0.isEmpty } }
        )
    }

    private func openLinkedInSearch() {
        let query = [contact.fullName, contact.company]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Try LinkedIn deep-link first, fall back to web search
        if let linkedInApp = URL(string: "linkedin://search?q=\(encoded)"),
           UIApplication.shared.canOpenURL(linkedInApp) {
            UIApplication.shared.open(linkedInApp)
        } else if let web = URL(string: "https://www.linkedin.com/search/results/people/?keywords=\(encoded)") {
            UIApplication.shared.open(web)
        }
    }

    private func saveContact() {
        Task {
            let hasAccess = await ContactsService.shared.requestAccess()
            guard hasAccess else {
                await MainActor.run {
                    saveState = .error("Contacts permission denied.")
                }
                return
            }
            do {
                try ContactsService.shared.saveContact(contact)
                await MainActor.run {
                    saveState = .saved
                }
            } catch {
                await MainActor.run {
                    saveState = .error(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - LinkedIn Paste Sheet
struct LinkedInPasteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var linkedinUrl: String
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.18).ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("Paste LinkedIn URL")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Open LinkedIn, find the profile, tap Share → Copy Link, then paste it here.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    TextField("https://linkedin.com/in/...", text: $draft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    Button("Attach URL") {
                        linkedinUrl = draft
                        dismiss()
                    }
                    .disabled(draft.isEmpty || !draft.contains("linkedin"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                }
                .padding(.top, 40)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
