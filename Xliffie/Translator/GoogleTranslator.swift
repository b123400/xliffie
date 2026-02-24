//
//  GoogleTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

class GoogleTranslator: Translator {
    let apiKey: String
    var referer: String?

    init(apiKey: String, referer: String? = nil) {
        self.apiKey = apiKey
        self.referer = referer
        super.init()
    }

    // MARK: Batch

    override func toBatches(texts: [String]) -> [[String]] {
        stride(from: 0, to: texts.count, by: 200).map {
            Array(texts[$0..<min($0 + 200, texts.count)])
        }
    }

    // MARK: Translate

    override func translate(texts: [String], sourceLocale: String, targetLocale: String) async throws -> [String] {
        let batches = toBatches(texts: texts)
        let source = filteredLocale(sourceLocale)
        let target = filteredLocale(targetLocale) ?? targetLocale

        return try await withThrowingTaskGroup(of: (Int, [String]).self) { group in
            for (index, batch) in batches.enumerated() {
                group.addTask {
                    let results = try await self.translateBatch(batch, source: source, target: target)
                    return (index, results)
                }
            }
            var ordered: [(Int, [String])] = []
            for try await result in group {
                ordered.append(result)
            }
            return ordered.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
        }
    }

    private func translateBatch(_ texts: [String], source: String?, target: String) async throws -> [String] {
        let url = URL(string: "https://www.googleapis.com/language/translate/v2")!
        var params = "key=\(apiKey)&format=text&prettyprint=false"
        if let source {
            params += "&source=\(source)"
        }
        params += "&target=\(target)"
        for text in texts {
            let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            params += "&q=\(encoded)"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("GET", forHTTPHeaderField: "X-HTTP-Method-Override")
        request.httpBody = Data(params.utf8)
        if let referer {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TranslationError.networkError(nil)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any],
              let translations = dataDict["translations"] as? [[String: Any]] else {
            throw TranslationError.parseError
        }
        return translations.compactMap { $0["translatedText"] as? String }
    }

    // MARK: Locale filtering

    // Massages locale codes to make Google Translate happy.
    // Returns nil if the locale should be omitted (e.g. auto-detect).
    private func filteredLocale(_ code: String) -> String? {
        guard code.count > 3 else { return code }
        if code == "zh-Hant" || code == "zh-TW" { return "zh-TW" }
        if code.hasSuffix("input") { return nil }
        return String(code.prefix(2))
    }
}
