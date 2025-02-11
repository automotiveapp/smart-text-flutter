//
//  SmartTextFlutterBridge.swift
//  Runner
//
//  Created by Jamiu Okanlawon on 09/03/2024.
//

import Foundation

protocol TextClassifier {
    func classifyText(text: String) -> [ItemSpan]
}

class AppleTextClassifier : TextClassifier {
    func classifyText(text: String) -> [ItemSpan] {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        
        let detector = NSDataDetector(dataTypes: DataDetectorType.allCases)
        
        let itemSpans: [DataDetectorResult] = detector.findMatches(in: normalizedText)
        
        return generateSmartTextItemsFromLinks(text: normalizedText, links: itemSpans)
    }
    
    private func generateSmartTextItemsFromLinks(text: String, links: [DataDetectorResult]) -> [ItemSpan] {
        var resultList = [ItemSpan]()
        
        if links.isEmpty {
            return text.isEmpty ? [ItemSpan(text: text, type: "text",rawValue: text)] : []
        }
        
        var previousEnd = 0
        
        for link in links {
            let textBefore = String(text[text.index(text.startIndex, offsetBy: previousEnd)..<text.index(text.startIndex, offsetBy: link.start)])
            if !textBefore.isEmpty {
                resultList.append(ItemSpan(text: textBefore, type: "text",rawValue: textBefore))
            }
            
            let entityType = link.type
            let linkType: String
            let rawValue: String
            
            switch entityType {
            case .address(let address):
                linkType = "address"
                rawValue = address
            case .phone(let phone):
                linkType = "phone"
                rawValue = phone
            case .email(let email):
                linkType = "email"
                rawValue = email
            case .datetime(let date):
                linkType = "datetime"
                rawValue = date
            case .url(let url):
                linkType = "url"
                rawValue = url
            }
            
            let startIndex = text.index(text.startIndex, offsetBy: link.start, limitedBy: text.endIndex)
            let endIndex = text.index(text.startIndex, offsetBy: link.end, limitedBy: text.endIndex)

            if let startIndex = startIndex, let endIndex = endIndex, startIndex <= endIndex {
                let linkText = String(text[startIndex..<endIndex])
                let linkSpan = ItemSpan(text: linkText, type: linkType, rawValue: rawValue)
                resultList.append(linkSpan)
            } else {
                print("Invalid string indices: link.start = \(link.start), link.end = \(link.end)")
            }
            previousEnd = link.end
        }
        
       if let lastLink = links.last {
    if lastLink.end <= text.count { 
        let startIndex = text.index(text.startIndex, offsetBy: lastLink.end)
        let textAfter = String(text[startIndex...])

        if !textAfter.isEmpty {
            resultList.append(ItemSpan(text: textAfter, type: "text", rawValue: textAfter))
        }
    } else {
        print("Invalid string indices: link.start = \(lastLink.start), link.end = \(lastLink.end), text length = \(text.count)")
    }
}
        
        return resultList
    }
}

struct ItemSpan {
    let text: String
    let type: String
    let rawValue: String
    
    func toMap() -> [String: Any] {
        return [
            "text": text,
            "type": type,
            "rawValue": rawValue
        ]
    }
}
