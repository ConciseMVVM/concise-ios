//
//  RealmSetup.swift
//  Todo
//
//  Created by Ethan Nagel on 7/30/20.
//  Copyright © 2020 Nagel Technologies. All rights reserved.
//

import Foundation
import RealmSwift
import ConciseRealm

class RealmSetup {
    private static func seedDatabase() {
        print("Seeding database with initial items...")
        
        try! writeRealm { (realm) in
            
            func add(_ name: String, _ items: [String]) {
                let list = TodoList(name: name)
                
                realm.add(list)
                
                for title in items {
                    realm.add(TodoItem(list: list, title: title))
                }
            }

            add("Shopping List", ["Bananas", "Apples", "Toothpaste", "Ramen"])
            add("Work", ["Schedule Stand ups", "Offline support mutations"])
            add("Personal", ["Go shopping", "Research camping trip locations"])
            add("House", ["Clean up back yard", "Fix leaky sink in kitchen"])
        }
    }
    
    /// configures & initializes realm database instance
    static func configure() {        
        var cfg = Realm.Configuration()
        
        cfg.deleteRealmIfMigrationNeeded = true
        
        // Whenever we create a default realm instance it will use this configuration...
        
        Realm.Configuration.defaultConfiguration = cfg
        
        // The first time we open the realm it will delete the instance and recreate it if there are
        // significant schema changes.
        
        do {
            let realm = try Realm()
            print("REALM: \(realm.configuration.fileURL?.absoluteString ?? "Error")")
        } catch {
            fatalError("Failed to open realm: \(error)")
        }
        
        // if the database appears empty, go ahead and initialize it with some data...
        
        if try! withRealm({ $0.objects(TodoList.self).count == 0}) {
            seedDatabase()
        }
    }
}
