//
//  NewsViewModel.swift
//  News
//
//  Created by Yoyo on 3/18/21.
//

import Foundation
import RxSwift
import RxCocoa

class NewsViewModel {
    let navigator: NewsNavigateProtocol
    
    init(navigator: NewsNavigateProtocol) {
        self.navigator = navigator
    }
}

extension NewsViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
        let reloadTrigger: Driver<Void>
        let loadMoreTrigger: Driver<Void>
        
        let selectCell: Driver<IndexPath>
        let changeCategory: Driver<Category>
    }
    
    struct Output {
        let items: Driver<[Article]>
        let openDetail: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let items = input.changeCategory// input.loadTrigger
            //.withLatestFrom(input.changeCategory)
            .flatMapFirst ({ category -> Driver<[Article]> in
                let url = Endpoint.news(category).url!
                
                return API.request(url: url)
                    .asDriver(onErrorJustReturn: Response())
                    .map { (response) -> [Article] in
                        return response.articles ?? []
                    }
            })
            .startWith([])
            .debug("aaa")

        let openDetail = input.selectCell
            .withLatestFrom(items) { (indexPath, list) -> Article? in
                if list.count > indexPath.row {
                    return list[indexPath.row]
                }
                
                return nil
            }
            .compactMap({ $0 })
            .do(onNext: { [weak self] in
                self?.navigator.openDetail(article: $0)
            })
            .mapToVoid()
        
        return Output(
            items: items,
            openDetail: openDetail
        )
    }
}