import Foundation

/// A language the reader can choose. Each language pins the app to the country
/// (or region) where it's primarily spoken, and to a news outlet covering it.
///
/// Six "rich" languages have per-section feeds from a national outlet; the rest
/// use a single reliable feed (national broadcaster or BBC World Service).
enum Language: String, CaseIterable, Codable, Identifiable {
    // Rich, per-category national outlets.
    case english, spanish, french, german, italian, japanese
    // National broadcasters (single feed).
    case dutch, norwegian, swedish, danish, finnish, vietnamese, indonesian
    // BBC World Service language services (single feed).
    case hindi, arabic, persian, russian, turkish, ukrainian, portuguese
    case chinese, korean, thai, tamil, urdu, bengali, swahili, hausa
    case gujarati, marathi, punjabi, telugu, nepali, sinhala, burmese
    case pashto, uzbek, kyrgyz, azeri, somali, amharic, tigrinya
    case igbo, yoruba, pidgin, kinyarwanda

    var id: String { rawValue }

    private var info: Info { Self.table[self] ?? Self.table[.english]! }
    var nativeName: String { info.nativeName }
    var country: String { info.country }
    var flag: String { info.flag }
    var outlet: String { info.outlet }
    var feeds: [Category: [(String, String)]] { info.feeds }

    /// BCP-47 code for choosing a matching text-to-speech voice, e.g. "es-ES".
    var speechLanguage: String {
        googleHL.contains("-") ? googleHL : "\(googleHL)-\(googleGL)"
    }

    /// Right-to-left scripts, so the UI can mirror its layout.
    var isRTL: Bool {
        switch self {
        case .arabic, .persian, .urdu, .pashto: return true
        default: return false
        }
    }

    /// Localized age-bracket blurb shown in Settings (falls back to English).
    func bracketBlurb(_ bracket: AgeBracket) -> String {
        L.t(bracket.blurb, self)
    }

    /// Google News edition: hl = interface/content language, gl = edition country.
    /// Used for the "news about a country, in my language" feature.
    var googleHL: String { Self.googleEdition[self]?.0 ?? "en" }
    var googleGL: String { Self.googleEdition[self]?.1 ?? "US" }

    private static let googleEdition: [Language: (String, String)] = [
        .english: ("en", "GB"), .spanish: ("es", "ES"), .french: ("fr", "FR"),
        .german: ("de", "DE"), .italian: ("it", "IT"), .japanese: ("ja", "JP"),
        .dutch: ("nl", "NL"), .norwegian: ("no", "NO"), .swedish: ("sv", "SE"),
        .danish: ("da", "DK"), .finnish: ("fi", "FI"), .vietnamese: ("vi", "VN"),
        .indonesian: ("id", "ID"), .hindi: ("hi", "IN"), .arabic: ("ar", "EG"),
        .persian: ("fa", "IR"), .russian: ("ru", "RU"), .turkish: ("tr", "TR"),
        .ukrainian: ("uk", "UA"), .portuguese: ("pt", "BR"), .chinese: ("zh-CN", "CN"),
        .korean: ("ko", "KR"), .thai: ("th", "TH"), .tamil: ("ta", "IN"),
        .urdu: ("ur", "PK"), .bengali: ("bn", "BD"), .swahili: ("sw", "TZ"),
        .hausa: ("ha", "NG"), .gujarati: ("gu", "IN"), .marathi: ("mr", "IN"),
        .punjabi: ("pa", "IN"), .telugu: ("te", "IN"), .nepali: ("ne", "NP"),
        .sinhala: ("si", "LK"), .burmese: ("my", "MM"), .pashto: ("ps", "AF"),
        .uzbek: ("uz", "UZ"), .kyrgyz: ("ky", "KG"), .azeri: ("az", "AZ"),
        .somali: ("so", "SO"), .amharic: ("am", "ET"), .tigrinya: ("ti", "ER"),
        .igbo: ("ig", "NG"), .yoruba: ("yo", "NG"), .pidgin: ("en", "NG"),
        .kinyarwanda: ("rw", "RW"),
    ]

    struct Info {
        let nativeName: String
        let country: String
        let flag: String
        let outlet: String
        let feeds: [Category: [(String, String)]]
    }

    // MARK: Feed-map builders

    /// One feed used for every category (fallback happens in `Feeds`).
    private static func single(_ outlet: String, _ url: String) -> [Category: [(String, String)]] {
        [.world: [(outlet, url)]]
    }

    /// A BBC World Service language feed.
    private static func bbc(_ service: String) -> [Category: [(String, String)]] {
        single("BBC", "https://feeds.bbci.co.uk/\(service)/rss.xml")
    }

    /// A national outlet with per-section feeds. Kids' categories (animals,
    /// space) route to the science feed so younger readers never fall through to
    /// general headlines; crime routes to the top feed.
    private static func sections(
        _ outlet: String, top: String, world: String, science: String,
        technology: String, environment: String, sports: String,
        business: String, politics: String
    ) -> [Category: [(String, String)]] {
        [
            .world: [(outlet, world)], .science: [(outlet, science)],
            .technology: [(outlet, technology)], .environment: [(outlet, environment)],
            .sports: [(outlet, sports)], .animals: [(outlet, science)],
            .space: [(outlet, science)], .politics: [(outlet, politics)],
            .business: [(outlet, business)], .crime: [(outlet, top)],
        ]
    }

    static let table: [Language: Info] = [
        .english: Info(nativeName: "English", country: "United Kingdom", flag: "🇬🇧",
                       outlet: "BBC · The Guardian", feeds: englishFeeds),
        .spanish: Info(nativeName: "Español", country: "Spain", flag: "🇪🇸", outlet: "El País",
                       feeds: sections("El País",
                           top: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/portada",
                           world: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/internacional/portada",
                           science: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/ciencia/portada",
                           technology: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/tecnologia/portada",
                           environment: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/ciencia/portada",
                           sports: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/deportes/portada",
                           business: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/economia/portada",
                           politics: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/espana/portada")),
        .french: Info(nativeName: "Français", country: "France", flag: "🇫🇷", outlet: "Le Figaro",
                      feeds: sections("Le Figaro",
                          top: "https://www.lefigaro.fr/rss/figaro_actualites.xml",
                          world: "https://www.lefigaro.fr/rss/figaro_international.xml",
                          science: "https://www.lefigaro.fr/rss/figaro_sciences.xml",
                          technology: "https://www.lefigaro.fr/rss/figaro_secteur_high-tech.xml",
                          environment: "https://www.lefigaro.fr/rss/figaro_sciences.xml",
                          sports: "https://www.lefigaro.fr/rss/figaro_sport.xml",
                          business: "https://www.lefigaro.fr/rss/figaro_economie.xml",
                          politics: "https://www.lefigaro.fr/rss/figaro_actualites.xml")),
        .german: Info(nativeName: "Deutsch", country: "Germany", flag: "🇩🇪", outlet: "Der Spiegel",
                      feeds: sections("Der Spiegel",
                          top: "https://www.spiegel.de/schlagzeilen/tops/index.rss",
                          world: "https://www.spiegel.de/ausland/index.rss",
                          science: "https://www.spiegel.de/wissenschaft/index.rss",
                          technology: "https://www.spiegel.de/netzwelt/index.rss",
                          environment: "https://www.spiegel.de/wissenschaft/index.rss",
                          sports: "https://www.spiegel.de/sport/index.rss",
                          business: "https://www.spiegel.de/wirtschaft/index.rss",
                          politics: "https://www.spiegel.de/schlagzeilen/tops/index.rss")),
        .italian: Info(nativeName: "Italiano", country: "Italy", flag: "🇮🇹", outlet: "ANSA",
                       feeds: sections("ANSA",
                           top: "https://www.ansa.it/sito/ansait_rss.xml",
                           world: "https://www.ansa.it/sito/notizie/mondo/mondo_rss.xml",
                           science: "https://www.ansa.it/canale_ambiente/notizie/ambiente_rss.xml",
                           technology: "https://www.ansa.it/canale_tecnologia/notizie/tecnologia_rss.xml",
                           environment: "https://www.ansa.it/canale_ambiente/notizie/ambiente_rss.xml",
                           sports: "https://www.ansa.it/sito/notizie/sport/sport_rss.xml",
                           business: "https://www.ansa.it/sito/notizie/economia/economia_rss.xml",
                           politics: "https://www.ansa.it/sito/ansait_rss.xml")),
        .japanese: Info(nativeName: "日本語", country: "Japan", flag: "🇯🇵", outlet: "NHK",
                        feeds: sections("NHK",
                            top: "https://www3.nhk.or.jp/rss/news/cat0.xml",
                            world: "https://www3.nhk.or.jp/rss/news/cat6.xml",
                            science: "https://www3.nhk.or.jp/rss/news/cat3.xml",
                            technology: "https://www3.nhk.or.jp/rss/news/cat3.xml",
                            environment: "https://www3.nhk.or.jp/rss/news/cat3.xml",
                            sports: "https://www3.nhk.or.jp/rss/news/cat7.xml",
                            business: "https://www3.nhk.or.jp/rss/news/cat5.xml",
                            politics: "https://www3.nhk.or.jp/rss/news/cat4.xml")),

        .dutch: Info(nativeName: "Nederlands", country: "Netherlands", flag: "🇳🇱", outlet: "NOS",
                     feeds: single("NOS", "https://feeds.nos.nl/nosnieuwsalgemeen")),
        .norwegian: Info(nativeName: "Norsk", country: "Norway", flag: "🇳🇴", outlet: "NRK",
                         feeds: single("NRK", "https://www.nrk.no/toppsaker.rss")),
        .swedish: Info(nativeName: "Svenska", country: "Sweden", flag: "🇸🇪", outlet: "SVT",
                       feeds: single("SVT", "https://www.svt.se/nyheter/rss.xml")),
        .danish: Info(nativeName: "Dansk", country: "Denmark", flag: "🇩🇰", outlet: "DR",
                      feeds: single("DR", "https://www.dr.dk/nyheder/service/feeds/allenyheder")),
        .finnish: Info(nativeName: "Suomi", country: "Finland", flag: "🇫🇮", outlet: "Yle",
                       feeds: single("Yle", "https://feeds.yle.fi/uutiset/v1/majorHeadlines/YLE_UUTISET.rss")),
        .vietnamese: Info(nativeName: "Tiếng Việt", country: "Vietnam", flag: "🇻🇳", outlet: "VnExpress",
                          feeds: single("VnExpress", "https://vnexpress.net/rss/tin-moi-nhat.rss")),
        .indonesian: Info(nativeName: "Bahasa Indonesia", country: "Indonesia", flag: "🇮🇩", outlet: "Antara",
                          feeds: single("Antara", "https://www.antaranews.com/rss/terkini")),

        .hindi: Info(nativeName: "हिन्दी", country: "India", flag: "🇮🇳", outlet: "BBC", feeds: bbc("hindi")),
        .arabic: Info(nativeName: "العربية", country: "the Arab world", flag: "🌍", outlet: "BBC", feeds: bbc("arabic")),
        .persian: Info(nativeName: "فارسی", country: "Iran", flag: "🇮🇷", outlet: "BBC", feeds: bbc("persian")),
        .russian: Info(nativeName: "Русский", country: "Russia", flag: "🇷🇺", outlet: "BBC", feeds: bbc("russian")),
        .turkish: Info(nativeName: "Türkçe", country: "Türkiye", flag: "🇹🇷", outlet: "BBC", feeds: bbc("turkce")),
        .ukrainian: Info(nativeName: "Українська", country: "Ukraine", flag: "🇺🇦", outlet: "BBC", feeds: bbc("ukrainian")),
        .portuguese: Info(nativeName: "Português", country: "Brazil", flag: "🇧🇷", outlet: "BBC", feeds: bbc("portuguese")),
        .chinese: Info(nativeName: "中文", country: "China", flag: "🇨🇳", outlet: "BBC", feeds: bbc("zhongwen/simp")),
        .korean: Info(nativeName: "한국어", country: "South Korea", flag: "🇰🇷", outlet: "BBC", feeds: bbc("korean")),
        .thai: Info(nativeName: "ไทย", country: "Thailand", flag: "🇹🇭", outlet: "BBC", feeds: bbc("thai")),
        .tamil: Info(nativeName: "தமிழ்", country: "India & Sri Lanka", flag: "🇮🇳", outlet: "BBC", feeds: bbc("tamil")),
        .urdu: Info(nativeName: "اردو", country: "Pakistan", flag: "🇵🇰", outlet: "BBC", feeds: bbc("urdu")),
        .bengali: Info(nativeName: "বাংলা", country: "Bangladesh", flag: "🇧🇩", outlet: "BBC", feeds: bbc("bengali")),
        .swahili: Info(nativeName: "Kiswahili", country: "East Africa", flag: "🌍", outlet: "BBC", feeds: bbc("swahili")),
        .hausa: Info(nativeName: "Hausa", country: "Nigeria", flag: "🇳🇬", outlet: "BBC", feeds: bbc("hausa")),
        .gujarati: Info(nativeName: "ગુજરાતી", country: "India", flag: "🇮🇳", outlet: "BBC", feeds: bbc("gujarati")),
        .marathi: Info(nativeName: "मराठी", country: "India", flag: "🇮🇳", outlet: "BBC", feeds: bbc("marathi")),
        .punjabi: Info(nativeName: "ਪੰਜਾਬੀ", country: "India & Pakistan", flag: "🇮🇳", outlet: "BBC", feeds: bbc("punjabi")),
        .telugu: Info(nativeName: "తెలుగు", country: "India", flag: "🇮🇳", outlet: "BBC", feeds: bbc("telugu")),
        .nepali: Info(nativeName: "नेपाली", country: "Nepal", flag: "🇳🇵", outlet: "BBC", feeds: bbc("nepali")),
        .sinhala: Info(nativeName: "සිංහල", country: "Sri Lanka", flag: "🇱🇰", outlet: "BBC", feeds: bbc("sinhala")),
        .burmese: Info(nativeName: "မြန်မာ", country: "Myanmar", flag: "🇲🇲", outlet: "BBC", feeds: bbc("burmese")),
        .pashto: Info(nativeName: "پښتو", country: "Afghanistan", flag: "🇦🇫", outlet: "BBC", feeds: bbc("pashto")),
        .uzbek: Info(nativeName: "Oʻzbek", country: "Uzbekistan", flag: "🇺🇿", outlet: "BBC", feeds: bbc("uzbek")),
        .kyrgyz: Info(nativeName: "Кыргызча", country: "Kyrgyzstan", flag: "🇰🇬", outlet: "BBC", feeds: bbc("kyrgyz")),
        .azeri: Info(nativeName: "Azərbaycan", country: "Azerbaijan", flag: "🇦🇿", outlet: "BBC", feeds: bbc("azeri")),
        .somali: Info(nativeName: "Soomaali", country: "Somalia", flag: "🇸🇴", outlet: "BBC", feeds: bbc("somali")),
        .amharic: Info(nativeName: "አማርኛ", country: "Ethiopia", flag: "🇪🇹", outlet: "BBC", feeds: bbc("amharic")),
        .tigrinya: Info(nativeName: "ትግርኛ", country: "Eritrea & Ethiopia", flag: "🇪🇷", outlet: "BBC", feeds: bbc("tigrinya")),
        .igbo: Info(nativeName: "Igbo", country: "Nigeria", flag: "🇳🇬", outlet: "BBC", feeds: bbc("igbo")),
        .yoruba: Info(nativeName: "Yorùbá", country: "Nigeria", flag: "🇳🇬", outlet: "BBC", feeds: bbc("yoruba")),
        .pidgin: Info(nativeName: "Naijá (Pidgin)", country: "Nigeria", flag: "🇳🇬", outlet: "BBC", feeds: bbc("pidgin")),
        .kinyarwanda: Info(nativeName: "Kinyarwanda", country: "Rwanda", flag: "🇷🇼", outlet: "BBC", feeds: bbc("gahuza")),
    ]

    // English keeps two reputable sources per category.
    private static let englishFeeds: [Category: [(String, String)]] = [
        .world: [("BBC", "https://feeds.bbci.co.uk/news/world/rss.xml"),
                 ("The Guardian", "https://www.theguardian.com/world/rss")],
        .science: [("BBC", "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml"),
                   ("The Guardian", "https://www.theguardian.com/science/rss")],
        .technology: [("BBC", "https://feeds.bbci.co.uk/news/technology/rss.xml"),
                      ("The Guardian", "https://www.theguardian.com/technology/rss")],
        .environment: [("The Guardian", "https://www.theguardian.com/environment/rss"),
                       ("BBC", "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml")],
        .sports: [("BBC", "https://feeds.bbci.co.uk/sport/rss.xml"),
                  ("The Guardian", "https://www.theguardian.com/sport/rss")],
        .animals: [("The Guardian", "https://www.theguardian.com/environment/wildlife/rss")],
        .space: [("The Guardian", "https://www.theguardian.com/science/space/rss")],
        .politics: [("BBC", "https://feeds.bbci.co.uk/news/politics/rss.xml"),
                    ("The Guardian", "https://www.theguardian.com/politics/rss")],
        .business: [("BBC", "https://feeds.bbci.co.uk/news/business/rss.xml"),
                    ("The Guardian", "https://www.theguardian.com/business/rss")],
        .crime: [("BBC", "https://feeds.bbci.co.uk/news/uk/rss.xml"),
                 ("The Guardian", "https://www.theguardian.com/law/rss")],
    ]
}
