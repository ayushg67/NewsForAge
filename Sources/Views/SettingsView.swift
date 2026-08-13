import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(SpeechService.self) private var speech
    @State private var editingAge = false
    @State private var ageText = ""

    var body: some View {
        @Bindable var settings = settings
        let lang = settings.language
        // Translate a Settings string into the chosen language.
        func t(_ s: String) -> String { L.t(s, lang) }

        return NavigationStack {
            Form {
                Section(t("Language & region")) {
                    Picker(t("Language"), selection: $settings.language) {
                        ForEach(Language.allCases.sorted {
                            $0.nativeName.localizedCaseInsensitiveCompare($1.nativeName) == .orderedAscending
                        }) { language in
                            Text("\(language.flag) \(language.nativeName)").tag(language)
                        }
                    }
                    LabeledContent(t("News from"), value: lang.country)
                    Text(String(format: t("News revolves around %@, from %@."), lang.country, lang.outlet))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(t("Focus on a country")) {
                    Picker(t("Country"), selection: $settings.countryCode) {
                        Text("🌐 \(t("Worldwide"))").tag(String?.none)
                        ForEach(Country.all.sorted {
                            $0.name(in: lang).localizedCaseInsensitiveCompare($1.name(in: lang)) == .orderedAscending
                        }) { country in
                            Text("\(country.flag) \(country.name(in: lang))")
                                .tag(String?.some(country.code))
                        }
                    }
                    Text(t("Pick a country to read about it in your language."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(t("Reading aloud")) {
                    Toggle(t("Read articles aloud"), isOn: $settings.speechEnabled)

                    if settings.speechEnabled {
                        Picker(t("Voice"), selection: $settings.voiceIdentifier) {
                            Text(t("Automatic")).tag(String?.none)
                            ForEach(SpeechService.voices(for: lang.speechLanguage), id: \.identifier) { voice in
                                Text("\(voice.name) · \(voice.quality.label)")
                                    .tag(String?.some(voice.identifier))
                            }
                        }
                        Button {
                            speech.speak(L.t("Opening an article reads it aloud.", lang),
                                         languageCode: lang.speechLanguage,
                                         voiceIdentifier: settings.voiceIdentifier)
                        } label: {
                            Label(t("Preview voice"), systemImage: "play.circle.fill")
                        }
                        Text("For the most natural voices, download Enhanced or Premium voices in iOS Settings ▸ Accessibility ▸ Spoken Content ▸ Voices.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(t("Opening an article reads it aloud."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: settings.speechEnabled) { _, enabled in
                    if !enabled { speech.stop() }
                }
                .onChange(of: settings.language) { _, _ in
                    settings.voiceIdentifier = nil  // reset to automatic when language changes
                }

                Section(t("Your profile")) {
                    LabeledContent(t("Age"), value: settings.age.map(String.init) ?? "—")
                    LabeledContent(t("Feed"), value: settings.bracket.title)
                    Button(t("Change age")) {
                        ageText = settings.age.map(String.init) ?? ""
                        editingAge = true
                    }
                }

                Section(t("What you can see")) {
                    Text(lang.bracketBlurb(settings.bracket))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(settings.bracket.allowedCategories) { category in
                        Label(category.title, systemImage: category.symbol)
                    }
                }

                Section(t("About")) {
                    LabeledContent(t("Sources"), value: lang.outlet)
                    Text(t("News is grouped by age so younger readers see suitable topics."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Created by Ayush Gupta.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(t("Settings"))
            .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
            .alert(t("Change age"), isPresented: $editingAge) {
                TextField(t("Age"), text: $ageText)
                    .keyboardType(.numberPad)
                Button(t("Save")) {
                    if let value = Int(ageText), (1...120).contains(value) {
                        settings.age = value
                    }
                }
                Button(t("Cancel"), role: .cancel) {}
            } message: {
                Text(t("Your feed updates to match your age."))
            }
        }
    }
}
