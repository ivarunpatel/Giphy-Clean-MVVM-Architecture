//
//  FeedViewController.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit

public final class FeedViewController: UIViewController {
    @IBOutlet private(set) public var tableView: UITableView!
    
    private var viewModel: FeedViewModellable?
    
    public init(viewModel: FeedViewModellable) {
        self.viewModel = viewModel
        super.init(nibName: "FeedViewController", bundle: Bundle(for: FeedViewController.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var refreshControl: UIRefreshControl?
    public var feedListItemViewModel = [FeedListItemViewModel]() {
        didSet {
            guaranteeMainThread { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRefreshControl()
        setupTableView()
        bindViewModel()
        viewModel?.viewDidLoad()
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(didPerformPullToRefresh), for: .valueChanged)
    }
 
    private func setupTableView() {
        tableView.register(UINib(nibName: "FeedItemCell", bundle: Bundle(for: FeedItemCell.self)), forCellReuseIdentifier: "FeedItemCell")
        tableView.addSubview(refreshControl!)
    }
    
    @objc private func didPerformPullToRefresh() {
        viewModel?.didRefreshFeed()
    }
    
    private func bindViewModel() {
        viewModel?.state.subscribe(listner: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .none:
                guaranteeMainThread { [weak self] in
                    self?.refreshControl?.endRefreshing()
                }
            case .loading:
                guaranteeMainThread { [weak self] in
                    self?.refreshControl?.beginRefreshing()
                }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedItemCell") as! FeedItemCell
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
    
func guaranteeMainThread(work: @escaping () -> Void) {
    if Thread.isMainThread {
        work()
    } else {
        DispatchQueue.main.async {
            work()
        }
    }
}
