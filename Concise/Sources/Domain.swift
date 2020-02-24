//
//  Domain.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class Domain {
    static public var current: Domain = Domain()  // todo - make this per thread
    
    private(set) public var needsUpdate: Bool = false
    
    private var _pendingVars: [AbstractVar] = []
    
    private var _afterUpdateBlocks: [() -> Void] = []
    
    private func setNeedsUpdate() {
        if !needsUpdate {
            needsUpdate = true
            // delay the update to the next run loop
            DispatchQueue.main.async {
                self.updatePendingValues()
            }
        }
    }
    
    public func addPendingVar(_ anyVar: AbstractVar) {
        guard !anyVar.needsUpdate else {
            return
        }
        
        _pendingVars.append(anyVar)
        anyVar.needsUpdate = true
        
        self.setNeedsUpdate()
    }
    
    private func updatePendingValues() {
        var index = 0
        
        while index < _pendingVars.count {
            let anyVar = _pendingVars[index]
            
            anyVar.updatingValue = true
            let changed = anyVar.updateValue()
            anyVar.updatingValue = false
            anyVar.needsUpdate = false
            
            if changed {
                anyVar.notifyChanged()
            }
            
            index += 1
        }
        
        _pendingVars = []
        needsUpdate = false
        
        if !_afterUpdateBlocks.isEmpty {
            let blocks = _afterUpdateBlocks
            _afterUpdateBlocks = []
            blocks.forEach({ $0() })
        }
        
    }
    
    public func willRead(_ observable: AbstractVar) {
        // Capture this dependency if we have an active dependency group...
        DependencyGroup.current?.addDependency(observable)
    }

    public func afterUpdate( _ block: @escaping () -> Void) {
        // pass to main thread if on background...
        
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.afterUpdate(block)
            }
        }
        
        _afterUpdateBlocks.append(block)
        setNeedsUpdate()
    }
}

