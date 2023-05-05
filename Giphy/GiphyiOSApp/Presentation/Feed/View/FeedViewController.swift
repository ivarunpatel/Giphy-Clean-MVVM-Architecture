//
//  FeedViewController.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit

public final class FeedViewController: UIViewController {
    
    private var viewModel: FeedViewModellable?
    
    convenience public init(viewModel: FeedViewModellable) {
        self.init()
        self.viewModel = viewModel
    }
    
    public let tableView = UITableView()
    public var refreshControl: UIRefreshControl?
    public var feedListItemViewModel = [FeedListItemViewModel]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupRefreshControl()
        bindViewModel()
        viewModel?.viewDidLoad()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(didPerformPullToRefresh), for: .valueChanged)
    }
    
    @objc private func didPerformPullToRefresh() {
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

extension FeedViewController: UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedListItemViewModel.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FeedItemCell()
        let feedListItemViewModel = feedListItemViewModel[indexPath.row]
        cell.configure(with: feedListItemViewModel)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
