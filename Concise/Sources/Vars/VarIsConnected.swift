//
//  VarIsConnected.swift
//  Concise
//
//  Created by Ethan Nagel on 3/8/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import Network

public class VarIsConnected: Var<Bool> {
    public static let shared = VarIsConnected()
    
    private var monitor: NWPathMonitor
    private var isConnected: Bool = false
    
    public var simulateOffline: Bool = false {
        didSet { setNeedsUpdate() }
    }
    
    public init() {
        monitor = NWPathMonitor()
        isConnected = monitor.currentPath.status == .satisfied
        super.init(Domain.current, isConnected)
        
        monitor.pathUpdateHandler = { [weak self] (path) in
            guard let self = self else {
                return
            }
            
            let newValue = path.status == .satisfied
            
            if newValue != self.isConnected {
                self.isConnected = newValue
                self.setNeedsUpdate()
            }
        }
        
        monitor.start(queue: DispatchQueue.main)
    }
    
    override public func updateValue() -> Bool {
        let newValue = (simulateOffline) ? false : isConnected
        
        if newValue == self.value {
            return false
        }
        
        setValue(newValue)
        return true
    }
    
    deinit {
        self.monitor.cancel()
    }
}
