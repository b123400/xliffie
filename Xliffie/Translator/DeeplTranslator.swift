//
//  DeeplTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

class DeeplTranslator: Translator {
    let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }

    // MARK: Batch

    // DeepL accepts up to 50 texts per request.
    override func toBatches(texts: [String]) -> [[String]] {
        stride(from: 0, to: texts.count, by: 50).map {
            Array(texts[$0..<min($0 + 50, texts.count)])
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
        let url = URL(string: "https://api-free.deepl.com/v2/translate")!

        var body: [String: Any] = [
            "text": texts,
            "target_lang": target,
        ]
        if let source {
            body["source_lang"] = source
        }
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TranslationError.networkError(nil)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translations = json["translations"] as? [[String: Any]] else {
            throw TranslationError.parseError
        }
        return try translations.map { item in
            guard let text = item["text"] as? String else {
                throw TranslationError.parseError
            }
            return text
        }
    }

    // MARK: Locale filtering

    // Massages locale codes to make DeepL happy.
    // Returns nil if the locale should be omitted (e.g. auto-detect).
    private func filteredLocale(_ code: String) -> String? {
        guard code.count > 3 else { return code }
        if code == "zh-Hant" || code == "zh-TW" { return "zh-TW" }
        if code.hasSuffix("input") { return nil }
        return String(code.prefix(2))
    }
}
