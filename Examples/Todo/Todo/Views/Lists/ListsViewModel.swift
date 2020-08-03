//
//  ListsVIewModel.swift
//  Todo
//
//  Created by Ethan Nagel on 7/29/20.
//  Copyright © 2020 Nagel Technologies. All rights reserved.
//

import Foundation
import Concise
import Realm
import RealmSwift
import ConciseRealm

class ListsViewModel: ViewModel {
    @VarProp var totalIncomplete: Int
    @ArrayProp var items: [Item]
    
    override init() {
        super.init()
        
        _totalIncomplete *= TodoItem.conciseCount({ $0.filter("isComplete == FALSE") })
        _items *= TodoList.conciseQuery({ $0.sorted(byKeyPath: "name") }).map({ Item($0) })
    }
}

extension ListsViewModel {
    class Item: ViewModelItem {
        let id: String
        @VarProp var name: String
        @VarProp var incompleteCount: Int
        
        init(_ list: TodoList) {
            self.id = list.id
            super.init()
            
            _name *= { list.name }
            _incompleteCount *= TodoItem.conciseCount({ $0.filter("list == %@ AND isComplete == FALSE", list) })
        }
    }
}
