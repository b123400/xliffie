//
//  CustomGlossaryDatabase.swift
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

import Foundation
import SQLite3

let CUSTOM_GLOSSARY_DATABASE_UPDATED_NOTIFICATION = "CUSTOM_GLOSSARY_DATABASE_UPDATED_NOTIFICATION"

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension Notification.Name {
    static let customGlossaryDatabaseUpdated = Notification.Name(CUSTOM_GLOSSARY_DATABASE_UPDATED_NOTIFICATION)
}

@objc class CustomGlossaryDatabase: NSObject, CustomGlossaryImporterDelegate {

    @objc static let shared = CustomGlossaryDatabase()

    @objc var notificationEnabled: Bool = true

    private var sqlite: OpaquePointer?

    override init() {
        super.init()
        open()
        notificationEnabled = true
    }

    deinit {
        if let sqlite = sqlite {
            sqlite3_close(sqlite)
        }
    }

    private var databasePath: String {
        let documentPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docPath = documentPaths.last!.path
        let dbPath = (docPath as NSString).appendingPathComponent("custom_glossary.db")
        NSLog("custom db path %@", dbPath)
        return dbPath
    }

    @discardableResult
    private func open() -> Bool {
        if sqlite != nil { return true }

        var dbConnection: OpaquePointer?
        let rc = sqlite3_open_v2(databasePath, &dbConnection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        if rc != SQLITE_OK {
            return false
        }
        sqlite = dbConnection
        query("CREATE TABLE IF NOT EXISTS glossary (id INTEGER PRIMARY KEY AUTOINCREMENT, source_locale varchar(255) NULL, target_locale varchar(255) NULL, source text NOT NULL, target text NOT NULL);", params: [])
        return true
    }

    @objc @discardableResult
    func insert(withSourceLocale sourceLocale: String?, targetLocale: String?, source: String, target: String) -> CustomGlossaryRow {
        let insertResult = query(
            "INSERT INTO glossary (source_locale, target_locale, source, target) VALUES (?, ?, ?, ?) RETURNING id, source_locale, target_locale, source, target",
            params: [
                sourceLocale as AnyObject? ?? NSNull(),
                targetLocale as AnyObject? ?? NSNull(),
                source as AnyObject,
                target as AnyObject,
            ]
        )
        if notificationEnabled {
            NotificationCenter.default.post(name: .customGlossaryDatabaseUpdated, object: self)
        }
        return rowsToObjects(insertResult).first!
    }

    @objc func deleteRow(_ row: CustomGlossaryRow) {
        query("DELETE FROM glossary WHERE id = ?", params: [row.id ?? NSNull()])
        if notificationEnabled {
            NotificationCenter.default.post(name: .customGlossaryDatabaseUpdated, object: self)
        }
    }

    @objc func updateRow(_ row: CustomGlossaryRow) {
        query(
            "UPDATE glossary SET source_locale = ?, target_locale = ?, source = ?, target = ? WHERE id = ?",
            params: [
                row.sourceLocale as AnyObject? ?? NSNull(),
                row.targetLocale as AnyObject? ?? NSNull(),
                row.source as AnyObject,
                row.target as AnyObject,
                row.id ?? NSNull(),
            ]
        )
        if notificationEnabled {
            NotificationCenter.default.post(name: .customGlossaryDatabaseUpdated, object: self)
        }
    }

    @objc func rows(withSourceLocale sourceLocale: String?, targetLocale: String?, source: String) -> [CustomGlossaryRow] {
        return rows(
            withSourceLocales: Utilities.fallbacks(withLocale: sourceLocale),
            targetLocales: Utilities.fallbacks(withLocale: targetLocale),
            source: source
        )
    }

    private func rows(withSourceLocales sourceLocales: [String], targetLocales: [String], source: String) -> [CustomGlossaryRow] {
        var sourcePlaceholders = ""
        var targetPlaceholders = ""
        var params: [AnyObject] = []

        for l in sourceLocales {
            if !sourcePlaceholders.isEmpty { sourcePlaceholders += "," }
            sourcePlaceholders += "?"
            params.append(l.lowercased().replacingOccurrences(of: "_", with: "-") as AnyObject)
        }
        for l in targetLocales {
            if !targetPlaceholders.isEmpty { targetPlaceholders += "," }
            targetPlaceholders += "?"
            params.append(l.lowercased().replacingOccurrences(of: "_", with: "-") as AnyObject)
        }

        let sourceCondition = sourceLocales.isEmpty ? "" : "REPLACE(LOWER(source_locale), '_', '-') IN (\(sourcePlaceholders)) OR"
        let targetCondition = targetLocales.isEmpty ? "" : "REPLACE(LOWER(target_locale), '_', '-') IN (\(targetPlaceholders)) OR"
        let sql = "SELECT id, source_locale, target_locale, source, target FROM glossary WHERE (\(sourceCondition) source_locale IS NULL) AND (\(targetCondition) target_locale IS NULL) AND source = ? COLLATE NOCASE"
        params.append(source as AnyObject)

        return rowsToObjects(query(sql, params: params))
    }

    @objc func allRows() -> [CustomGlossaryRow] {
        return rowsToObjects(query("SELECT id, source_locale, target_locale, source, target FROM glossary", params: []))
    }

    @objc func doesRowExist(withSourceLocale sourceLocale: String?, targetLocale: String?, source: String, target: String) -> Bool {
        let sourceLocales = Utilities.fallbacks(withLocale: sourceLocale)
        let targetLocales = Utilities.fallbacks(withLocale: targetLocale)
        var sourcePlaceholders = ""
        var targetPlaceholders = ""
        var params: [AnyObject] = []

        for l in sourceLocales {
            if !sourcePlaceholders.isEmpty { sourcePlaceholders += "," }
            sourcePlaceholders += "?"
            params.append(l.lowercased().replacingOccurrences(of: "_", with: "-") as AnyObject)
        }
        for l in targetLocales {
            if !targetPlaceholders.isEmpty { targetPlaceholders += "," }
            targetPlaceholders += "?"
            params.append(l.lowercased().replacingOccurrences(of: "_", with: "-") as AnyObject)
        }

        let sourceCondition = sourceLocales.isEmpty ? "" : "REPLACE(LOWER(source_locale), '_', '-') IN (\(sourcePlaceholders)) OR"
        let targetCondition = targetLocales.isEmpty ? "" : "REPLACE(LOWER(target_locale), '_', '-') IN (\(targetPlaceholders)) OR"
        let sql = "SELECT COUNT(id) FROM glossary WHERE (\(sourceCondition) source_locale IS NULL) AND (\(targetCondition) target_locale IS NULL) AND source = ? AND target = ? COLLATE NOCASE"
        params.append(source as AnyObject)
        params.append(target as AnyObject)

        let countRows = query(sql, params: params)
        if let count = countRows.first?.first as? NSNumber, count.intValue >= 1 {
            return true
        }
        return false
    }

    private func rowsToObjects(_ rows: [[Any]]) -> [CustomGlossaryRow] {
        return rows.map { columns in
            let r = CustomGlossaryRow()
            r.id = columns[0] as? NSNumber
            r.sourceLocale = (columns[1] is NSNull) ? nil : columns[1] as? String
            r.targetLocale = (columns[2] is NSNull) ? nil : columns[2] as? String
            r.source = columns[3] as? String ?? ""
            r.target = columns[4] as? String ?? ""
            return r
        }
    }

    @discardableResult
    private func query(_ sql: String, params: [AnyObject]) -> [[Any]] {
        if !open() { return [] }

        var compiledStatement: OpaquePointer?
        let rc = sqlite3_prepare_v2(sqlite, sql, -1, &compiledStatement, nil)
        if rc != SQLITE_OK {
            NSLog("Cannot prepare sql (%d) : %@", rc, sql)
            return []
        }

        for (i, param) in params.enumerated() {
            if let str = param as? String {
                sqlite3_bind_text(compiledStatement, Int32(i + 1), str, -1, SQLITE_TRANSIENT)
            } else if let num = param as? NSNumber {
                sqlite3_bind_int64(compiledStatement, Int32(i + 1), num.int64Value)
            } else if param is NSNull {
                sqlite3_bind_null(compiledStatement, Int32(i + 1))
            }
        }

        var result: [[Any]] = []
        while sqlite3_step(compiledStatement) == SQLITE_ROW {
            var row: [Any] = []
            for i in 0..<sqlite3_column_count(compiledStatement) {
                let colType = sqlite3_column_type(compiledStatement, i)
                let value: Any
                switch colType {
                case SQLITE_TEXT:
                    let col = sqlite3_column_text(compiledStatement, i)!
                    value = String(cString: col)
                case SQLITE_INTEGER:
                    value = NSNumber(value: sqlite3_column_int(compiledStatement, i))
                case SQLITE_FLOAT:
                    value = NSNumber(value: sqlite3_column_double(compiledStatement, i))
                case SQLITE_NULL:
                    value = NSNull()
                default:
                    NSLog("%s Unknown data type.", #function)
                    value = NSNull()
                }
                row.append(value)
            }
            result.append(row)
        }
        sqlite3_finalize(compiledStatement)
        return result
    }

    // MARK: - CSV Export

    @objc func exportToFile(_ path: String, withTotalCount total: Int64, callback: @escaping (Error?) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: total)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, self.open() else {
                callback(NSError(domain: "net.b123400.xliffie.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot open database"]))
                return
            }

            let writer = CHCSVWriter(forWritingToCSVFile: path)
            writer?.writeLine(ofFields: NSArray(array: ["source_locale", "target_locale", "source", "target"]))

            let sql = "SELECT source_locale, target_locale, source, target FROM glossary"
            var compiledStatement: OpaquePointer?
            let rc = sqlite3_prepare_v2(self.sqlite, sql, -1, &compiledStatement, nil)
            if rc != SQLITE_OK {
                NSLog("Cannot prepare sql (%d) : %@", rc, sql)
                callback(NSError(domain: "net.b123400.xliffie.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot prepare export SQL"]))
                return
            }

            var completeCount: Int64 = 0
            while sqlite3_step(compiledStatement) == SQLITE_ROW {
                for i in 0..<sqlite3_column_count(compiledStatement) {
                    let colType = sqlite3_column_type(compiledStatement, i)
                    if colType == SQLITE_TEXT {
                        let col = sqlite3_column_text(compiledStatement, i)!
                        writer?.writeField(String(cString: col))
                    } else if colType == SQLITE_NULL {
                        writer?.writeField("")
                    } else {
                        NSLog("%s Unknown data type.", #function)
                    }
                }
                writer?.finishLine()
                completeCount += 1
                progress.completedUnitCount = completeCount
            }
            sqlite3_finalize(compiledStatement)
            callback(nil)
        }

        return progress
    }

    @objc func importWithFile(_ url: URL, callback: @escaping (Error?) -> Void) -> Progress {
        notificationEnabled = false
        let importer = CustomGlossaryImporter()
        importer.delegate = self
        return importer.importFromFile(url, withCallback: { [weak self] error in
            guard let self = self else { return }
            self.notificationEnabled = true
            callback(error)
            NotificationCenter.default.post(name: .customGlossaryDatabaseUpdated, object: self)
        })
    }

    // MARK: - CustomGlossaryImporterDelegate

    func didReadRow(_ row: CustomGlossaryRow, fromImporter importer: CustomGlossaryImporter) {
        insert(withSourceLocale: row.sourceLocale, targetLocale: row.targetLocale, source: row.source, target: row.target)
    }
}
