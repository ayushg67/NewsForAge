import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(SpeechService.self) private var speech
    @State private var editingAge = false
    @State private var ageText = ""

    var body: some View {
        @Bindable var settings = settings
        return NavigationStack {
            Form {
                Section("Reading aloud") {
                    Toggle("Read articles aloud", isOn: $settings.speechEnabled)
                    Text("When on, opening an article speaks the headline and summary.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .onChange(of: settings.speechEnabled) { _, enabled in
                    if !enabled { speech.stop() }
                }

                Section("Your profile") {
                    LabeledContent("Age", value: settings.age.map(String.init) ?? "—")
                    LabeledContent("Feed", value: settings.bracket.title)
                    Button("Change age") {
                        ageText = settings.age.map(String.init) ?? ""
                        editingAge = true
                    }
                }

                Section("What you can see") {
                    Text(settings.bracket.blurb)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(settings.bracket.allowedCategories) { category in
                        Label(category.title, systemImage: category.symbol)
                    }
                }

                Section("About") {
                    LabeledContent("Sources", value: "BBC · The Guardian")
                    Text("News is grouped into age brackets so younger readers see only suitable topics. Stories come from public RSS feeds.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Created by Ayush Gupta.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Change age", isPresented: $editingAge) {
                TextField("Age", text: $ageText)
                    .keyboardType(.numberPad)
                Button("Save") {
                    if let value = Int(ageText), (1...120).contains(value) {
                        settings.age = value
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your feed updates to match your age.")
            }
        }
    }
}
