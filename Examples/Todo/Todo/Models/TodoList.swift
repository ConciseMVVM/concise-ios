//
//  TodoList.swift
//  Todo
//
//  Created by Ethan Nagel on 7/29/20.
//  Copyright © 2020 Nagel Technologies. All rights reserved.
//

import Foundation
import RealmSwift
import Concise
import ConciseRealm

class TodoList: ConciseObject, Identifiable {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var dateCreated = Date()
    @objc dynamic var name = ""
    
    public let items = LinkingObjects(fromType: TodoItem.self, property: "list")
    
    override class func primaryKey() -> String? { "id" }
    override class func indexedProperties() -> [String] { ["name"] }
    override class func ignoredProperties() -> [String] { ["allItems", "incompleteItems"] }
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}

