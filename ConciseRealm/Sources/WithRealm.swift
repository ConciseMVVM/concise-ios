//
//  WithRealm.swift
//  ConciseRealm
//
//  Created by Ethan Nagel on 3/12/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import RealmSwift

public func withRealm<T>(_ block: (_ realm: Realm) throws -> T) throws -> T {
    let realm = try Realm()
    
    return try block(realm)
}

public func writeRealm<T>(_ block: (_ realm: Realm) throws -> T) throws -> T {
    let realm = try Realm()
    
    var result: T?
    try realm.write { result = try block(realm) }
    
    return result!
}

public func writeRealm<T>(_ block: () throws -> T) throws -> T {
    return try writeRealm { _ in
        return try block()
    }
}

public func writeRealmAsync(queue: DispatchQueue? = nil, _ block: @escaping (_ realm: Realm) throws -> Void) {
    let queue = queue ?? DispatchQueue.global()
    
    queue.async {
        do {
            let realm = try Realm()
            try realm.write { try block(realm) }
        } catch {
            // what can we do about this??
            print("writeRealmAsync exception: \(error)")
        }
    }
}

public func writeRealmAsync(_ block: @escaping () throws -> Void) {
    writeRealmAsync { _ in
        try block()
    }
}

