//
//  FeedViewController.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit

public final class FeedViewController: UITableViewController {
    private var viewModel: FeedViewModellable?
    
    convenience public init(viewModel: FeedViewModellable) {
        self.init()
        self.viewModel = viewModel
    }
    
    public var feedListItemViewModel = [FeedListItemViewModel]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        viewModel?.viewDidLoad()
    }
 
    @IBAction private func didPerformPullToRefresh() {
        viewModel?.didRefreshFeed()
    }
    
    private func bindViewModel() {
        viewModel?.state.subscribe(listner: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .none:
                refreshControl?.endRefreshing()
            case .loading:
                refreshControl?.beginRefreshing()
            case .nextPage:
                break
            }
        })
        
        viewModel?.items.subscribe(listner: { [weak self] feedItems in
            guard let self = self else { return }
            feedListItemViewModel = feedItems
        })
    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedListItemViewModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FeedItemCell()
        let feedListItemViewModel = feedListItemViewModel[indexPath.row]
        cell.configure(with: feedListItemViewModel)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let feedListItemViewModel = feedListItemViewModel[indexPath.row]
        feedListItemViewModel.didCancelImageRequest()
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let feedListItemViewModel = feedListItemViewModel[indexPath.row]
            feedListItemViewModel.didRequestGif()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let feedListItemViewModel = feedListItemViewModel[indexPath.row]
            feedListItemViewModel.didCancelImageRequest()
        }
    }
}
