//
//  ConciseTableViewDataSource.swift
//  Concise
//
//  Created by Ethan Nagel on 7/31/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import UIKit

public protocol ConciseTableViewSectionDataSource: UITableViewDataSource, Subscription {
    var section: Int { get set }
    var applyChanges: (_ dataSource: ConciseTableViewSectionDataSource, _ inserts: [IndexPath], _ deletes: [IndexPath]) -> Void { get set }
    var tableView: UITableView? { get set }
}

public class ConciseTableViewSingleSectionDataSource<Element: ConciseBindableViewModelItem>: NSObject, ConciseTableViewSectionDataSource where Element.View: UITableViewCell {
    public typealias Cell = Element.View
    
    public var section: Int = 0
    private var subscription: Subscription?
    private var isFirstUpdate = true
    public let data: ConciseArray<Element>
    public var applyChanges: (_ dataSource: ConciseTableViewSectionDataSource, _ inserts: [IndexPath], _ deletes: [IndexPath]) -> Void
    public weak var tableView: UITableView? = nil
    
    public required init(_ data: ConciseArray<Element>) {
        self.data = data
        self.applyChanges = Self.defaultApplyChanges
        super.init()
        
        subscription = data.subscribe { [weak self] in
            guard let self = self else { return }
            
            if data.oldItems.isEmpty && self.isFirstUpdate {
                self.applyChanges(self, [], []) // reload section
                self.isFirstUpdate = false
                
            } else if !data.changes.isEmpty {
                let inserts = data.changes.insertions.map({ IndexPath(row: $0, section: self.section) })
                let deletes = data.changes.removals.map({ IndexPath(row: $0, section: self.section) })
                
                self.applyChanges(self, inserts, deletes)
                self.isFirstUpdate = false
            }
        }
    }
    
    deinit {
        self.dispose()
    }
    
    public func dispose() {
        subscription = nil
    }
            
    public static func defaultApplyChanges(_ dataSource: ConciseTableViewSectionDataSource, _ inserts: [IndexPath], _ deletes: [IndexPath]) {
        guard let tableView = dataSource.tableView else { return }
        
        // this applyChanges method is sufficient for single-section tables. Multi-section table updates are
        // handeled by ConciseTableViewMultiSectionDataSource
        
        if inserts.isEmpty && deletes.isEmpty {
            tableView.reloadData()
        } else {
            tableView.performBatchUpdates({
                tableView.insertRows(at: inserts, with: .automatic)
                tableView.deleteRows(at: deletes, with: .automatic)
            }, completion: nil)
        }
    }
        
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == self.section else { return 0 }

        if self.tableView == nil {
            self.tableView = tableView // will cause subscription to be set up in didSet as well
        }

        return self.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.data[indexPath.row]
        let cellType = Element.bindableViewTypeFor(item)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: cellType), for: indexPath) as? Cell else {
            fatalError("unable to deque cell of type \(cellType)")
        }
        
        cell.bind(to: item)
        
        return cell
    }
}

public class ConciseTableViewMultiSectionDataSource: NSObject, UITableViewDataSource, Subscription {
    enum PendingSectionChange {
        case reload(Int)
        case update([IndexPath], [IndexPath])
        
        var isReload: Bool {
            switch self {
            case .reload:
                return true
            default:
                return false
            }
        }
    }
    
    public private(set) var sections: [ConciseTableViewSectionDataSource]
    
    public var tableView: UITableView? = nil {
        didSet {
            for section in sections {
                section.tableView = tableView
            }
        }
    }
    
    private var isFirstUpdate = true
    private var pendingSectionChanges: [PendingSectionChange] = []
        
    public required init(_ sections: [ConciseTableViewSectionDataSource]) {
        self.sections = sections
        super.init()
        
        // initialize our sections...
        
        for (index, section) in sections.enumerated() {
            section.section = index
            section.applyChanges = { [weak self] (_, inserts, deletes) in
                self?.applySectionChanges(section, inserts, deletes)
            }
        }
    }
    
    deinit {
        self.dispose()
    }
    
    public func dispose() {
        for section in sections {
            section.dispose()
        }
    }
    
    private func applySectionChanges(_ section: ConciseTableViewSectionDataSource, _ inserts: [IndexPath], _ deletes: [IndexPath]) {
        let changes = (inserts.isEmpty && deletes.isEmpty) ? PendingSectionChange.reload(section.section) : PendingSectionChange.update(inserts, deletes)
        
        // We need to apply changes from all sections at the same time to make UITableView happy :(
        // To do this we build a list of PendingSectionChanges when updates are happening and use the
        // Domain afterUpdate feature to apply all the changes we collected at once.
        
        if pendingSectionChanges.isEmpty {
            Domain.current.afterUpdate {
                guard let tableView = self.tableView else { return }
                
                // if it's the first update and all sections are requesting a reload, then we need to reload ;)
                
                if self.isFirstUpdate && self.pendingSectionChanges.allSatisfy({ $0.isReload }) {
                    tableView.reloadData()

                } else if !self.pendingSectionChanges.isEmpty {
                    tableView.performBatchUpdates({
                        for change in self.pendingSectionChanges {
                            switch change {
                            case .reload(let section):
                                tableView.reloadSections(IndexSet(integer: section), with: .none)
                            case .update(let inserts, let deletes):
                                tableView.insertRows(at: inserts, with: .automatic)
                                tableView.deleteRows(at: deletes, with: .automatic)
                            }
                        }
                    }, completion: nil)
                }
                
                self.isFirstUpdate = false
                self.pendingSectionChanges = []
            }
        }
        
        pendingSectionChanges.append(changes)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        if self.tableView == nil {
            self.tableView = tableView  // will cause subscriptions to be set-up
        }
        
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].tableView(tableView, numberOfRowsInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].tableView(tableView, cellForRowAt: indexPath)
    }
}

extension ConciseArray where Element: ConciseBindableViewModelItem, Element.View: UITableViewCell {
    public var tableViewDataSource: ConciseTableViewSingleSectionDataSource<Element> {
        return ConciseTableViewSingleSectionDataSource(self)
    }
}

extension Array where Element: ConciseBindableViewModelItem, Element.View: UITableViewCell {
    public var tableViewDataSource: ConciseTableViewSingleSectionDataSource<Element> {
        let conciseArray = ConciseArray(domain: Domain.current, items: self)
        return conciseArray.tableViewDataSource
    }
}
