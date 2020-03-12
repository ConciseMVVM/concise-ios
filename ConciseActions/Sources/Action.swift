//  
//  DemoApp
//  Action
//
//  Created on 3/2/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation
import Concise
import RealmSwift

public enum ActionError: Error, CustomStringConvertible {
    case cancelled
    case dependencyUnsatisfiable(Dependency)
    
    public var description: String {
        switch self {
        case .cancelled: return "Action Cancelled"
        case .dependencyUnsatisfiable(let dep): return "Dependency is unsatisfiable: \(dep.description)"
        }
    }
}

open class Action: ActionPersistableObject, CustomStringConvertible {
    public var ref: ActionRef { return self.storage as! ActionRef }
    private(set) public var dependencies: [Dependency]
    
    @MutableProp private(set) public var isRunning: Bool = false
    @MutableProp private(set) public var cancelled: Bool = false
    
    public var isActive: Bool { ref.isActive }
    public var isCompleted: Bool { ref.isCompleted }
    public var errorMessage: String? { ref.errorMessage }
    public var refCount: Int {
        get { ref.refCount }
        set { ref.refCount = newValue } // only inside an asyncWrite block!
    }
    
    public var didSucceed: Bool { ref.isCompleted && ref.errorMessage == nil }
    public var didFail: Bool { ref.isCompleted && ref.errorMessage != nil }

    public required init(_ storage: ActionPersistableStorageObject) {
        guard let ref = storage as? ActionRef else {
            fatalError("Expected ActionRef")
        }
        self.dependencies = ref.dependencies.map({ $0.dependency })
        super.init(ref)
    }
    
    public var dependenciesAreSatisfied: Bool { dependencies.allSatisfy({ $0.isSatisified }) }
    public var dependenciesAreSatisfiable: Bool { dependencies.allSatisfy({ $0.isSatisifiable }) }
    
    public func addDependencies(_ deps: Dependency?...) {
        for dep in deps.compactMap({ $0 }) {
            ref.dependencies.append(dep.ref)
            dependencies.append(dep)
        }
    }
    
    public func cancel() {
        cancelled = true
    }
    
    open func start() {
        print("Starting action: \(self)")
        ActionManager.shared.writeAsync { (realm) in
            if self.ref.isCompleted || self.ref.isActive {
                return
            }
            
            self.ref.isActive = true
            
            self.onStarting(realm)
        }
    }

    private func complete(_ error: Error?) {

        // if we aren't being called from the main thread, dispatch to the main thread and call ourselves again...
        // this allows callers to call us from any thread safely
        
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.complete(error)
            }
            return
        }
        
        print("complete action \(self) - \(error?.localizedDescription ?? "success")")

        onCompleted(error)

        if let error = error {
            onError(error)
        } else {
            onSuccess()
        }
        
        ActionManager.shared.writeAsync { (_) in
            self.ref.isActive = false
            self.ref.isCompleted = true
            self.ref.errorMessage = error?.localizedDescription // text of error if failure or nil if success
            
            self.isRunning = false
        }
    }
    
    private func runOrCancel() {
        guard !self.cancelled else {
            complete(ActionError.cancelled)
            return
        }
        
        guard self.dependenciesAreSatisfiable else {
            guard let unsatisfiable = self.dependencies.first(where: { !$0.isSatisifiable }) else {
                fatalError("Expected to find unsatisfiable Dependency")
            }
            
            complete(ActionError.dependencyUnsatisfiable(unsatisfiable))
            return
        }
        
        self.isRunning = true
        
        print("onPerformAction \(self)")
        do {
            try self.onPerformAction(actionCompleted: self.complete)
        } catch {
            complete(error)
        }
    }

    /// start performing the Action if dependencies are satisfied or wait until they are satisfied and then perform the action
    internal func run() {
        self.writeAsync {
            guard !self.isRunning && self.isActive && !self.isCompleted else {
                return
            }
            
            let shouldRunOrCancel = Expr { self.cancelled || !self.dependenciesAreSatisfiable || self.dependenciesAreSatisfied }
            
            if shouldRunOrCancel.value {
                self.runOrCancel()
                return
            }
            
            var sub: Subscription?
                
            sub = shouldRunOrCancel.subscribe {
                guard shouldRunOrCancel.value else {
                    return
                }

                self.runOrCancel()
                
                if sub != nil {
                    sub = nil
                }
            }
        }
    }
    
    internal func delete() {
        self.writeAsync { (realm) in
            guard self.isCompleted && self.refCount == 0 else {
                return
            }
            
            print("deleting \(self)")
            
            // first let dependencies & actions know we are about to delete them...
            
            for dependency in self.dependencies {
                dependency.onDelete(from: realm)
            }
            self.onDelete(from: realm)
            
            // now, do the deed!
            
            realm.delete(self.ref.dependencies)
            realm.delete(self.ref)
        }
    }
    
    /// Called when the action is about to be started. Guaranteeed to be called once at most.
    open func onStarting(_ realm: Realm) {
    }
    
    open func onPerformAction(actionCompleted: @escaping (_ error: Error?) -> Void) throws {
    }

    /// called on completion, etiher success or error
    open func onCompleted(_ error: Error?) {
    }
    
    open func onSuccess() {
    }
    
    open func onError(_ error: Error) {
    }
    
    open func onDelete(from realm: Realm) {
    }
    
    public func writeAsync(_ block: @escaping (_ realm: Realm) -> Void) {
        ActionManager.shared.writeAsync(block)
    }
    
    public func writeAsync(_ block: @escaping () -> Void) {
        ActionManager.shared.writeAsync { (_) in block() }
    }

    open var description: String {
        let status: String = {
            if self.didSucceed {
                return "succeeded"
            } else if self.didFail {
                return "failed: \(self.errorMessage!)"
            } else if self.isRunning {
                return "running"
            } else {
                let deps = dependencies.filter({ !$0.isSatisified }).map( { $0.description }).joined(separator: ", ")
                
                return deps.isEmpty ? "ready" : "waiting for: \(deps)"
            }
        }()
        
        return "\(type(of: self))(\(self.id), \(status))"
    }
}
