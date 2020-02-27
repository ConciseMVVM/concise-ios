//
//  ConciseArrayChange.swift
//  Concise
//
//  Created by Ethan Nagel on 2/27/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public enum ConciseArrayChange {
    case insert(offset: Int)
    case remove(offset: Int)
}

extension ConciseArrayChange: CustomStringConvertible {
    public var description: String {
        switch self {
        case .insert(let offset): return "insert(\(offset))"
        case .remove(let offset): return "remove(\(offset))"
        }
    }
}

extension Array where Element == ConciseArrayChange {
    public var insertions: [Int] {
        return self.compactMap {
            switch $0 {
            case .insert(let offset):
                return offset
            default:
                return nil
            }
        }
    }
    
    public var removals: [Int] {
        return self.compactMap {
            switch $0 {
            case .remove(let offset):
                return offset
            default:
                return nil
            }
        }
    }
}

extension CollectionDifference {
    public func asConciseArrayChange() -> [ConciseArrayChange] {
        return self.map {
            switch $0 {
            case .insert(let offset, _, _): return .insert(offset: offset)
            case .remove(let offset, _, _): return .remove(offset: offset)
            }
        }
    }
}

