//  
//  DemoApp
//  ConnectedDependency
//
//  Created on 3/8/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation

import Concise

public class ConnectedDependency: Dependency {
    override public var isSatisified: Bool { VarIsConnected.shared.value }
}

extension Dependency {
    static public var connected: ConnectedDependency { ConnectedDependency() }
}
