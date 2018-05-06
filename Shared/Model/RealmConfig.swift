//
//  Database.swift
//  iOS
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

extension Realm {
    static func configureDefaultRealm() {
        var config = Realm.Configuration()
        config.fileURL = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("realm")
        try? FileManager.default.removeItem(at: config.fileURL!)
        Realm.Configuration.defaultConfiguration = config
    }
}
