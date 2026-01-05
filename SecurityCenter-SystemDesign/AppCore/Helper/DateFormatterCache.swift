//
//  DateFormatterCache.swift
//  SecurityCenter-SystemDesign
//
//  Created by 許佳豪 on 2026/1/5.
//

import Foundation

class DateFormatterCache {
    static let shared = DateFormatterCache()

    private let queue = DispatchQueue(label: "dev.date_formatter_cache", qos: .userInitiated)

    func getFormatter(forFormat format: String) -> DateFormatter {
        queue.sync {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en")
            formatter.setLocalizedDateFormatFromTemplate(format)
            return formatter
        }
    }

    private struct CacheKey: Hashable {
        let format: String
        let language: String
    }
}

extension DateFormatter {
    static func cachedFormatter(format: String) -> DateFormatter {
        DateFormatterCache.shared.getFormatter(forFormat: format)
    }
}
