//
//  DeeplTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

@objc class DeeplTranslator: Translator {
    let apiKey: String

    @objc init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }

    // MARK: Batch

    // DeepL accepts up to 50 texts per request.
    override var batchSize: Int {
        return 50
    }

    // MARK: Translate

    override func translateBatch(_ texts: [String], source: String?, target: String) async throws -> [String] {
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
            throw TranslationError.networkError
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
}
