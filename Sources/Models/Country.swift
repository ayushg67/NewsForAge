import Foundation

/// A country the reader can focus the news on. `nil` selection means worldwide.
///
/// Names are localized to the reader's language at runtime via `Locale`, so no
/// country name is hand-translated. The flag is derived from the ISO code.
struct Country: Identifiable, Hashable, Codable {
    let code: String   // ISO 3166-1 alpha-2, uppercase

    init(_ code: String) { self.code = code.uppercased() }

    var id: String { code }

    /// Regional-indicator flag emoji from the two-letter code.
    var flag: String {
        code.unicodeScalars.reduce("") { result, scalar in
            result + (UnicodeScalar(127397 + scalar.value).map(String.init) ?? "")
        }
    }

    var englishName: String {
        Locale(identifier: "en_US").localizedString(forRegionCode: code) ?? code
    }

    /// Country name in the given language, e.g. "Japón" for Spanish.
    func name(in language: Language) -> String {
        Locale(identifier: language.googleHL).localizedString(forRegionCode: code) ?? englishName
    }

    /// A curated, broad list of countries across every continent.
    static let all: [Country] = [
        "US", "GB", "CA", "AU", "IE", "NZ",
        "FR", "DE", "ES", "IT", "PT", "NL", "BE", "CH", "AT", "GR",
        "SE", "NO", "DK", "FI", "PL", "CZ", "HU", "RO", "UA", "RU",
        "TR", "IL", "SA", "AE", "QA", "EG", "IR", "IQ",
        "IN", "PK", "BD", "LK", "NP", "CN", "JP", "KR", "TW", "HK",
        "SG", "MY", "TH", "VN", "ID", "PH", "MM",
        "BR", "MX", "AR", "CO", "CL", "PE", "VE",
        "NG", "KE", "TZ", "GH", "ET", "ZA", "UG", "RW", "SO",
        "UZ", "KG", "AZ",
    ].map(Country.init)

    static func named(_ code: String) -> Country { Country(code) }
}
