//
//  TodoItem.swift
//  Todo
//
//  Created by Ethan Nagel on 7/29/20.
//  Copyright © 2020 Nagel Technologies. All rights reserved.
//

import Foundation

import RealmSwift
import ConciseRealm

class TodoItem: ConciseObject, Identifiable {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var dateCreated = Date()
    @objc dynamic var list: TodoList? = nil
    @objc dynamic var title = ""
    @objc dynamic var isComplete = false

    override class func primaryKey() -> String? { "id" }
    override class func indexedProperties() -> [String] { ["dateCreated", "isComplete"] }
    
    convenience init(list: TodoList, title: String) {
        self.init()
        self.list = list
        self.title = title
    }
}
