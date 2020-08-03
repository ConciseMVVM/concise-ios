//
//  ListsViewController.swift
//  Todo
//
//  Created by Ethan Nagel on 7/29/20.
//  Copyright © 2020 Nagel Technologies. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import RxBlocking
import ConciseRx
import Concise

class ListsViewController: UITableViewController {
    typealias VM = ListsViewModel
    
    var viewModel: VM!
    var bindings: DisposeBag? = nil
    
    private func bind() {
        bindings = DisposeBag.capture {
            self.rx.title *= { "All Lists (\(self.viewModel.totalIncomplete) todo)" }
            self.tableView.dataSource *= self.viewModel.$items
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = VM()
        bind()
    }
}

extension ListsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // todo, on no next view controller...
    }
}

extension ListsViewModel.Item: ConciseBindableViewModelItem {
    typealias View = ListsCell
}

class ListsCell: UITableViewCell, ConciseBindableView {
    var bindings: DisposeBag? = nil
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bindings = nil
    }
    
    func bind(to item: ListsViewModel.Item) {
        bindings = DisposeBag.capture {
            self.textLabel?.rx.text *= { "\(item.name) (\(item.incompleteCount))" }
        }
    }
}
