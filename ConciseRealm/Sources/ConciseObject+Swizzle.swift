//
//  ConciseObject+Swizzle.swift
//  ConciseRealm
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Concise

extension ConciseObject {
    
    private static func getSwizzledImp(type: RLMPropertyType, existingImp: IMP, injectBlock: @escaping (_ obj: ConciseObject) -> Void) -> IMP {
        switch(type) {
        case .int:
            return IMP.fromBlock((@convention(block) (ConciseObject, Selector) -> Int).self) { (obj, selector) in
                injectBlock(obj)
                return existingImp.cast(type: (@convention(c) (ConciseObject, Selector) -> Int).self) {
                    $0(obj, selector)
                }
            }
            
        case .bool:
            return IMP.fromBlock((@convention(block) (ConciseObject, Selector) -> Bool).self) { (obj, selector) in
                injectBlock(obj)
                return existingImp.cast(type: (@convention(c) (ConciseObject, Selector) -> Bool).self) {
                    $0(obj, selector)
                }
            }

        case .float:
            return IMP.fromBlock((@convention(block) (ConciseObject, Selector) -> Float).self) { (obj, selector) in
                injectBlock(obj)
                return existingImp.cast(type: (@convention(c) (ConciseObject, Selector) -> Float).self) {
                    $0(obj, selector)
                }
            }

        case .double:
            return IMP.fromBlock((@convention(block) (ConciseObject, Selector) -> Double).self) { (obj, selector) in
                injectBlock(obj)
                return existingImp.cast(type: (@convention(c) (ConciseObject, Selector) -> Double).self) {
                    $0(obj, selector)
                }
            }

        case .object, .date, .data, .string, .any, .linkingObjects:
            return IMP.fromBlock((@convention(block) (ConciseObject, Selector) -> AnyObject?).self) { (obj, selector) in
                injectBlock(obj)
                return existingImp.cast(type: (@convention(c) (ConciseObject, Selector) -> AnyObject?).self) {
                    $0(obj, selector)
                }
            }
        }
    }
    
    private static func swizzleProperty(_ target: ConciseObject.Type, _ property: RLMProperty) {
        let selector = property.getterSel
        
        guard let originalMethod = class_getInstanceMethod(target, selector) else {
            print("unable to get existing method for \(property.name)")
            return
        }
        
        guard let existingImp = class_getMethodImplementation(target, selector) else {
            print("unable to get existing imp")
            return
        }
        
        let propertyName = property.name
        
        
//        let className = class_getName(target)
//        print("swizzling \(String(cString: className)).\(propertyName)")
        
        
        let swizzledImp = getSwizzledImp(type: property.optional ? .object : property.type, existingImp: existingImp) {
            $0.willReadProperty(propertyName)
        }
        
        class_replaceMethod(target, selector, swizzledImp, method_getTypeEncoding(originalMethod))
    }
    
    internal static func swizzleClass(_ target: ConciseObject.Type) {
        guard let schema = target.sharedSchema() else {
            fatalError()
        }
        
        for property in schema.properties {
            swizzleProperty(target, property)
        }
    }
}

private extension IMP {
    func cast<T, U>(type: U.Type, block: (_ func: U) -> T) -> T {
        let value = unsafeBitCast(self, to: type)
        return block(value)
    }
    
    static func fromBlock<T>(_ type: T.Type, _ block: T) -> IMP {
        return imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
    }
}

