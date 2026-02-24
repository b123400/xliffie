//
//  GoogleTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

@objc class GoogleTranslator: Translator {
    let apiKey: String
    var referer: String?

    @objc init(apiKey: String, referer: String? = nil) {
        self.apiKey = apiKey
        self.referer = referer
        super.init()
    }

    // MARK: Batch

    // Google Translate API accepts up to 200 texts per request.
    override var batchSize: Int {
        return 200
    }

    // MARK: Translate

    override func translateBatch(_ texts: [String], source: String?, target: String) async throws -> [String] {
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
            throw TranslationError.networkError
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any],
              let translations = dataDict["translations"] as? [[String: Any]] else {
            throw TranslationError.parseError
        }
        return translations.compactMap { $0["translatedText"] as? String }
    }
}
