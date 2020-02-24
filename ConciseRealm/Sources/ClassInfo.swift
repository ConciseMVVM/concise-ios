//
//  ClassInfo.swift
//  SimpleMethod
//
//  Created by Ethan Nagel on 2/12/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

internal struct ClassInfo : CustomStringConvertible, Equatable {
    let classObject: AnyClass
    let classNameFull: String
    let className: String
    
    init?(_ classObject: AnyClass?) {
        guard let classObject = classObject else {
            return nil
        }
        
        self.classObject = classObject
        
        self.classNameFull = String(cString: class_getName(classObject))
        self.className = self.classNameFull.components(separatedBy: ".").last!
    }
    
    var superclassInfo: ClassInfo? {
        let superclassObject: AnyClass? = class_getSuperclass(self.classObject)
        return ClassInfo(superclassObject)
    }

    func hasSuperclass(_ superclass: AnyObject.Type) -> Bool {
        let name = String(cString: class_getName(superclass))
        
        var current = self.superclassInfo
        
        while current != nil {
            if current?.classNameFull == name {
                return true
            }
            
            current = current?.superclassInfo
        }
        
        return false
    }
    
    var description: String {
        return self.classNameFull
    }
    
    static func ==(lhs: ClassInfo, rhs: ClassInfo) -> Bool {
        return lhs.classNameFull == rhs.classNameFull
    }
    
    static var all: [ClassInfo] {
        
        var all: [ClassInfo] = []
        
        var count: UInt32 = 0
        let classList = objc_copyClassList(&count)!
        
        for i in 0..<Int(count) {
            if let classInfo = ClassInfo(classList[i]) {
                all.append(classInfo)
            }
        }
        
        return all
    }
}
