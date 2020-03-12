//  
//  DemoApp
//  Persistable
//
//  Created on 3/4/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation

/// Represents a value that may be stored in a @Persistent property.
/// Many standard types already conform to this prorocol (Int, String, etc.) You may add conformance
/// to your own classes, enums or structs
public protocol PersistableValue {
    func asPersistableString() -> String
    static func fromPersistableString(_ string: String) -> Self
}

// The following protocol extensions provide default implementations for common types such
// as RawRepresentable (enums) and Codable. For these types you only need to add protocol
// conformance.

extension RawRepresentable where Self: PersistableValue, RawValue: PersistableValue {
    public func asPersistableString() -> String {
        return rawValue.asPersistableString()
    }
    
    public static func fromPersistableString(_ string: String) -> Self {
        return self.init(rawValue: RawValue.fromPersistableString(string))!
    }
}

extension Encodable where Self: PersistableValue {
    public func asPersistableString() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return String(bytes: data, encoding: .utf8)!
    }
}

extension Decodable where Self: PersistableValue {
    public static func fromPersistableString(_ string: String) -> Self {
        let decoder = JSONDecoder()
        let data = string.data(using: .utf8)!
        return try! decoder.decode(Self.self, from: data)
    }
}

extension Optional: PersistableValue where Wrapped: PersistableValue {
    public func asPersistableString() -> String {
        switch self {
        case .none: return "none"
        case .some(let wrapped): return "some:" + wrapped.asPersistableString()
        }
    }
    
    public static func fromPersistableString(_ string: String) -> Optional<Wrapped> {
        if string.hasPrefix("some:") {
            return Wrapped.fromPersistableString(String(string.dropFirst(5)))
        }
        return Optional<Wrapped>.none // either "none" or something we don't recognize
    }
}

//extension FixedWidthInteger where Self: PersistableValue, Self: Codable {
//    public func asPersistableString() -> String {
//        return self.description
//    }
//
//    public static func fromPersistableString(_ string: String) -> Self {
//        return self.init(string)!
//    }
//}

extension Int: PersistableValue {
    public func asPersistableString() -> String {
        return self.description
    }
    
    public static func fromPersistableString(_ string: String) -> Self {
        return self.init(string)!
    }
}

extension UInt: PersistableValue {
    public func asPersistableString() -> String {
        return self.description
    }
    
    public static func fromPersistableString(_ string: String) -> Self {
        return self.init(string)!
    }
}

extension Bool: PersistableValue {
    public func asPersistableString() -> String {
        return self.description
    }
    
    public static func fromPersistableString(_ string: String) -> Self {
        return self.init(string)!
    }
}

extension String: PersistableValue {
    public func asPersistableString() -> String {
        return self
    }
    
    public static func fromPersistableString(_ string: String) -> String {
        return string
    }
}

extension Float: PersistableValue {
    public func asPersistableString() -> String {
        return self.description
    }
    
    public static func fromPersistableString(_ string: String) -> Self {
        return self.init(string)!
    }
}

extension Double: PersistableValue {
    public func asPersistableString() -> String {
        return self.description
    }
    
    public static func fromPersistableString(_ string: String) -> Self {
        return self.init(string)!
    }
}

/// An object that can host persistent storage for @Persistent properties
public protocol PersistableStorage {
    func setPersistentValue(_ key: String, _ value: String)
    func getPersistentValue(_ key: String) -> String?
}

public protocol PersistentPropertyWrapper: AnyObject {
    var persistentKey: String! { get set }
    var storage: PersistableStorage! { get set }
}

@propertyWrapper
/// A Properties whose backing is provided by an underlying PersistableStore provided by a Persistable instance. Must be a member of
/// a Persistable class
public class Persistent<T: PersistableValue>: PersistentPropertyWrapper {
    public var persistentKey: String!
    public var storage: PersistableStorage!
    public let defaultValue: T
    
    private func assertInitialized() {
        if persistentKey == nil || storage == nil {
            fatalError("Persistent property wrapper not initialized, is it a member of a Persistable class?")
        }
    }
    
    public var wrappedValue: T {
        get {
            assertInitialized()
            return storage.getPersistentValue(persistentKey).map({ T.fromPersistableString($0) }) ?? defaultValue
        }
        
        set {
            assertInitialized()
            storage.setPersistentValue(persistentKey, newValue.asPersistableString())
        }
    }
    
    public init(wrappedValue: T) {
        self.defaultValue = wrappedValue
    }
}

/// A class that can host @Persistent properties. Backing store is provided by a PersistableStorage instance.
public protocol Persistable {
}

extension Persistable {
    private static func enumeratePersistentProperties(mirror: Mirror, block: @escaping (_ name: String, _ property: PersistentPropertyWrapper) -> Void) {
        for prop in mirror.children {
            if let name = prop.label?.dropFirst(), let property = prop.value as? PersistentPropertyWrapper {
                block(String(name), property)
            }
        }
        
        if let superclassMirror = mirror.superclassMirror {
            enumeratePersistentProperties(mirror: superclassMirror, block: block)
        }
    }

    public func bindPersistentProperties(to storage: PersistableStorage) {
        Self.enumeratePersistentProperties(mirror: Mirror(reflecting: self)) { (name, property) in
            property.persistentKey = name
            property.storage = storage
        }
    }
}
