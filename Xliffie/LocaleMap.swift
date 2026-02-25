//
//  LocaleMap.swift
//  Xliffie
//
//  Maps Apple locale identifiers to the locale codes required by each
//  translation service API. Replaces the BRLocaleMap CocoaPod.
//

import Foundation

@objc final class LocaleMap: NSObject {

    // MARK: - Google Translate mapping
    // Keys are Apple locale identifiers (or prefixes); values are Google API language codes.
    private static let googleMapping: [String: String] = [
        "af":       "af",    // Afrikaans
        "sq":       "sq",    // Albanian
        "ar":       "ar",    // Arabic
        "hy":       "hy",    // Armenian
        "eu":       "eu",    // Basque
        "be":       "be",    // Belarusian
        "bn":       "bn",    // Bengali
        "bs":       "bs",    // Bosnian
        "bg":       "bg",    // Bulgarian
        "ca":       "ca",    // Catalan
        "zh":       "zh-TW", // Chinese — falls back to Traditional
        "zh_Hans":  "zh-CN", // Chinese (Simplified)
        "zh_Hant":  "zh-TW", // Chinese (Traditional)
        "hr":       "hr",    // Croatian
        "cs":       "cs",    // Czech
        "da":       "da",    // Danish
        "nl":       "nl",    // Dutch
        "en":       "en",    // English
        "eo":       "eo",    // Esperanto
        "et":       "et",    // Estonian
        "fil":      "tl",    // Filipino
        "fi":       "fi",    // Finnish
        "fr":       "fr",    // French
        "gl":       "gl",    // Galician
        "ka":       "ka",    // Georgian
        "de":       "de",    // German
        "el":       "el",    // Greek
        "gu":       "gu",    // Gujarati
        "ha":       "ha",    // Hausa
        "he":       "iw",    // Hebrew (Google uses legacy "iw")
        "hi":       "hi",    // Hindi
        "hu":       "hu",    // Hungarian
        "is":       "is",    // Icelandic
        "ig":       "ig",    // Igbo
        "id":       "id",    // Indonesian
        "ga":       "ga",    // Irish
        "it":       "it",    // Italian
        "ja":       "ja",    // Japanese
        "kn":       "kn",    // Kannada
        "kk":       "kk",    // Kazakh
        "km":       "km",    // Khmer
        "ko":       "ko",    // Korean
        "lo":       "lo",    // Lao
        "lv":       "lv",    // Latvian
        "lt":       "lt",    // Lithuanian
        "mk":       "mk",    // Macedonian
        "mg":       "mg",    // Malagasy
        "ms":       "ms",    // Malay
        "ml":       "ml",    // Malayalam
        "mt":       "mt",    // Maltese
        "mr":       "mr",    // Marathi
        "mn":       "mn",    // Mongolian
        "ne":       "ne",    // Nepali
        "nb":       "no",    // Norwegian Bokmål
        "nn":       "no",    // Norwegian Nynorsk
        "fa":       "fa",    // Persian
        "pl":       "pl",    // Polish
        "pt":       "pt",    // Portuguese
        "pa":       "ma",    // Punjabi
        "ro":       "ro",    // Romanian
        "ru":       "ru",    // Russian
        "sr":       "sr",    // Serbian
        "si":       "si",    // Sinhala
        "sk":       "sk",    // Slovak
        "sl":       "sl",    // Slovenian
        "so":       "so",    // Somali
        "es":       "es",    // Spanish
        "sw":       "sw",    // Swahili
        "sv":       "sv",    // Swedish
        "gsw":      "de",    // Swiss German → German
        "tg":       "tg",    // Tajik
        "ta":       "ta",    // Tamil
        "te":       "te",    // Telugu
        "th":       "th",    // Thai
        "tr":       "tr",    // Turkish
        "uk":       "uk",    // Ukrainian
        "ur":       "ur",    // Urdu
        "uz":       "uz",    // Uzbek
        "vi":       "vi",    // Vietnamese
        "cy":       "cy",    // Welsh
        "yi":       "yi",    // Yiddish
        "yo":       "yo",    // Yoruba
        "zu":       "zu",    // Zulu
    ]

    // MARK: - Microsoft Translator mapping
    // Keys are Apple locale identifiers (or prefixes); values are Microsoft API language codes.
    private static let microsoftMapping: [String: String] = [
        "ar":       "ar",       // Arabic
        "bs":       "bs",       // Bosnian
        "bg":       "bg",       // Bulgarian
        "ca":       "ca",       // Catalan
        "zh":       "zh-CHT",   // Chinese — falls back to Traditional
        "zh_Hans":  "zh-CHS",   // Chinese (Simplified)
        "zh_Hant":  "zh-CHT",   // Chinese (Traditional)
        "hr":       "hr",       // Croatian
        "cs":       "cs",       // Czech
        "da":       "da",       // Danish
        "nl":       "nl",       // Dutch
        "en":       "en",       // English
        "et":       "et",       // Estonian
        "fi":       "fi",       // Finnish
        "fr":       "fr",       // French
        "de":       "de",       // German
        "el":       "el",       // Greek
        "he":       "he",       // Hebrew
        "hi":       "hi",       // Hindi
        "hu":       "hu",       // Hungarian
        "id":       "id",       // Indonesian
        "it":       "it",       // Italian
        "ja":       "ja",       // Japanese
        "lv":       "lv",       // Latvian
        "lt":       "lt",       // Lithuanian
        "ms":       "ms",       // Malay
        "mt":       "mt",       // Maltese
        "nb":       "no",       // Norwegian Bokmål
        "nn":       "no",       // Norwegian Nynorsk
        "fa":       "fa",       // Persian
        "pl":       "pl",       // Polish
        "pt":       "pt",       // Portuguese
        "ro":       "ro",       // Romanian
        "ru":       "ru",       // Russian
        "sr":       "sr-Cyrl",  // Serbian (Cyrillic)
        "sr_Latn":  "sr-Latn",  // Serbian (Latin)
        "sk":       "sk",       // Slovak
        "sl":       "sl",       // Slovenian
        "es":       "es",       // Spanish
        "sv":       "sv",       // Swedish
        "gsw":      "de",       // Swiss German → German
        "th":       "th",       // Thai
        "tr":       "tr",       // Turkish
        "uk":       "uk",       // Ukrainian
        "ur":       "ur",       // Urdu
        "vi":       "vi",       // Vietnamese
        "cy":       "cy",       // Welsh
    ]

    // MARK: - DeepL supported locales (ISO 639-1 uppercase)
    private static let deeplSupportedLocales: Set<String> = [
        "AR", "BG", "CS", "DA", "DE", "EL", "EN", "ES", "ET", "FI",
        "FR", "HU", "ID", "IT", "JA", "KO", "LT", "LV", "NB", "NL",
        "PL", "PT", "RO", "RU", "SK", "SL", "SV", "TR", "UK", "ZH",
    ]

    // MARK: - Public API

    /// Returns the API language code for the given Apple locale identifier when used as a
    /// translation **source**, or `nil` if the service doesn't support that locale.
    @objc static func sourceLocale(_ localeCode: String, forService service: XLFTranslationService) -> String? {
        switch service {
        case .microsoft:
            return lookup(localeCode, in: microsoftMapping)
        case .google:
            return lookup(localeCode, in: googleMapping)
        case .deepl:
            guard localeCode.count >= 2 else { return nil }
            let prefix = String(localeCode.prefix(2)).uppercased()
            return deeplSupportedLocales.contains(prefix) ? prefix : nil
        case .native:
            return localeCode
        @unknown default:
            return nil
        }
    }

    /// Returns the API language code for the given Apple locale identifier when used as a
    /// translation **target**, or `nil` if the service doesn't support that locale.
    @objc static func targetLocale(_ localeCode: String, forService service: XLFTranslationService) -> String? {
        switch service {
        case .microsoft:
            return lookup(localeCode, in: microsoftMapping)
        case .google:
            return lookup(localeCode, in: googleMapping)
        case .deepl:
            return deeplTargetLocale(localeCode)
        case .native:
            return localeCode
        @unknown default:
            return nil
        }
    }

    // MARK: - Private helpers

    /// DeepL target locale mapping — handles regional variants for EN, PT, and ZH.
    private static func deeplTargetLocale(_ localeCode: String) -> String? {
        guard localeCode.count >= 2 else { return nil }
        let normalized = localeCode
            .replacingOccurrences(of: "-", with: "_")
            .lowercased()

        if normalized == "en_gb"           { return "EN-GB"   }
        if normalized == "en_us"           { return "EN-US"   }
        if normalized == "pt_br"           { return "PT-BR"   }
        if normalized == "pt_pt"           { return "PT-PT"   }
        if normalized.hasPrefix("zh_hans") { return "ZH-HANS" }
        if normalized.hasPrefix("zh_hant") { return "ZH-HANT" }

        let prefix = String(localeCode.prefix(2)).uppercased()
        return deeplSupportedLocales.contains(prefix) ? prefix : nil
    }

    /// Looks up `localeCode` in `mapping` using a fallback chain from most-specific to
    /// least-specific. E.g. "zh_Hant_HK" → tries ["zh_Hant_HK", "zh_Hant", "zh"].
    private static func lookup(_ localeCode: String, in mapping: [String: String]) -> String? {
        for candidate in fallbacks(for: localeCode) {
            if let code = mapping[candidate] {
                return code
            }
        }
        return nil
    }

    /// Generates the fallback locale chain for a given identifier, from most-specific to
    /// least-specific, by progressively trimming the trailing component.
    ///
    ///     fallbacks(for: "zh_Hant_HK") → ["zh_Hant_HK", "zh_Hant", "zh"]
    private static func fallbacks(for localeCode: String) -> [String] {
        var results = [localeCode]
        let chars = Array(localeCode)
        // Iterate from the end so longer prefixes are added before shorter ones.
        for i in stride(from: chars.count - 1, through: 0, by: -1) {
            if chars[i] == "-" || chars[i] == "_" {
                results.append(String(localeCode.prefix(i)))
            }
        }
        return results
    }
}
