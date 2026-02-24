//
//  BingTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

@objc class BingTranslator: Translator {
    let apiKey: String

    @objc init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }

    // MARK: Batch

    // Microsoft Translator API v3 accepts up to 100 elements per request.
    override var batchSize: Int {
        return 100
    }

    // MARK: Translate

    override func translateBatch(_ texts: [String], source: String?, target: String) async throws -> [String] {
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
            throw TranslationError.networkError
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
}
