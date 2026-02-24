//
//  BingTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

class BingTranslator: Translator {
    let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }

    // MARK: Batch

    // Microsoft Translator API v3 accepts up to 100 elements per request.
    override func toBatches(texts: [String]) -> [[String]] {
        stride(from: 0, to: texts.count, by: 100).map {
            Array(texts[$0..<min($0 + 100, texts.count)])
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
        var queryItems = [
            URLQueryItem(name: "api-version", value: "3.0"),
            URLQueryItem(name: "to", value: target),
        ]
        if let source {
            queryItems.append(URLQueryItem(name: "from", value: source))
        }

        var urlComponents = URLComponents(string: "https://api.cognitive.microsofttranslator.com/translate")!
        urlComponents.queryItems = queryItems
        let url = urlComponents.url!

        let body = texts.map { ["text": $0] }
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TranslationError.networkError(nil)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw TranslationError.parseError
        }
        return try json.map { item in
            guard let translations = item["translations"] as? [[String: Any]],
                  let text = translations.first?["text"] as? String else {
                throw TranslationError.parseError
            }
            return text
        }
    }

    // MARK: Locale filtering

    // Massages locale codes to make Microsoft Translator happy.
    // Returns nil if the locale should be omitted (e.g. auto-detect).
    private func filteredLocale(_ code: String) -> String? {
        guard code.count > 3 else { return code }
        if code == "zh-Hant" || code == "zh-TW" { return "zh-TW" }
        if code.hasSuffix("input") { return nil }
        return String(code.prefix(2))
    }
}
