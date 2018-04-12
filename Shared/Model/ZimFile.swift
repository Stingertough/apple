//
//  ZimFile.swift
//  iOS
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

class ZimFile: Object {
    @objc dynamic var id = ""
    @objc dynamic var pid: String?
    
    @objc dynamic var title = ""
    @objc dynamic var bookDescription = ""
    @objc dynamic var languageCode = ""
    @objc dynamic var creationDate = Date()
    
    @objc dynamic var creator = ""
    @objc dynamic var publisher = ""
    
    @objc dynamic var articleCount: Int64 = 0
    @objc dynamic var mediaCount: Int64 = 0
    @objc dynamic var globalCount: Int64 = 0
    @objc dynamic var fileSize: Int64 = 0
    
    @objc dynamic var hasPicture = false
    @objc dynamic var hasEmbeddedIndex = false
    @objc dynamic var includeInSearch = true
    
    @objc dynamic var icon = Data()
    
    @objc dynamic var remoteURL: String?
    
    @objc dynamic var stateRaw = ""
    @objc dynamic var categoryRaw = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var state: State {
        get { return State(rawValue:stateRaw) ?? .cloud }
        set { stateRaw = newValue.rawValue }
    }
    
    var category: Category {
        get { return Category(rawValue:stateRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    
//    @NSManaged public var totalBytesWritten: Int64
//    
//    @NSManaged public var articles: Set<Article>
//    @NSManaged public var language: Language?
    
    enum State: String, CustomStringConvertible {
        case cloud, downloadQueued, downloading, downloadPaused, downloadError, local, retained
        
        var description: String {
            switch self {
            case .cloud:
                return NSLocalizedString("Cloud", comment: "Book State")
            case .downloadQueued:
                return NSLocalizedString("Queued", comment: "Book State")
            case .downloading:
                return NSLocalizedString("Downloading", comment: "Book State")
            case .downloadPaused:
                return NSLocalizedString("Paused", comment: "Book State")
            case .downloadError:
                return NSLocalizedString("Error", comment: "Book State")
            case .local:
                return NSLocalizedString("Local", comment: "Book State")
            case .retained:
                return NSLocalizedString("Retained", comment: "Book State")
            }
        }
    }
    
    enum Category: String {
        case wikibooks
        case wikinews
        case wikipedia
        case wikiquote
        case wikisource
        case wikispecies
        case wikiversity
        case wikivoyage
        case wiktionary
        
        case ted
        case vikidia
        case stackExchange
        
        case other
    }
}