//
//  HomeCoordinator.swift
//  cybexMobile
//
//  Created koofrank on 2018/3/12.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift
import NBLCommonModule

protocol HomeCoordinatorProtocol {
    func openMarket(index: Int, currentBaseIndex: Int)
}

protocol HomeStateManagerProtocol {
    var state: HomeState { get }
    func switchPageState(_ state: PageState)
}

class HomeCoordinator: NavCoordinator {
    var store = Store(
        reducer: homeReducer,
        state: nil,
        middleware: [trackingMiddleware]
    )

    var state: HomeState {
        return store.state
    }

    override class func start(_ root: BaseNavigationController, context: RouteContext? = nil) -> BaseViewController {
        let vc = R.storyboard.main.homeViewController()!
        let coordinator = HomeCoordinator(rootVC: root)
        vc.coordinator = coordinator
        coordinator.store.dispatch(RouteContextAction(context: context))
        return vc
    }
}

extension HomeCoordinator: HomeCoordinatorProtocol {
    func openMarket(index: Int, currentBaseIndex: Int) {
        let vc = R.storyboard.main.marketViewController()!
        vc.curIndex = index
        vc.currentBaseIndex = currentBaseIndex
        vc.rechargeShowType = PairRechargeView.ShowType.show.rawValue

        let coordinator = MarketCoordinator(rootVC: self.rootVC)
        vc.coordinator = coordinator
        self.rootVC.pushViewController(vc, animated: true)
    }
}

extension HomeCoordinator: HomeStateManagerProtocol {
    func switchPageState(_ state: PageState) {
        self.store.dispatch(PageStateAction(state: state))
    }

}
