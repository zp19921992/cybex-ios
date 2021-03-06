//
//  WithdrawAddressHomeCoordinator.swift
//  cybexMobile
//
//  Created koofrank on 2018/8/13.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift
import NBLCommonModule
import SwiftyJSON
import HandyJSON

protocol WithdrawAddressHomeCoordinatorProtocol {
    func openWithDrawAddressVC()
}

protocol WithdrawAddressHomeStateManagerProtocol {
    var state: WithdrawAddressHomeState { get }

    func fetchData()
    func fetchAddressData()
    func selectCell(_ index: Int)
}

class WithdrawAddressHomeCoordinator: NavCoordinator {
    var store = Store<WithdrawAddressHomeState>(
        reducer: withdrawAddressHomeReducer,
        state: nil,
        middleware: [trackingMiddleware]
    )

    override func register() {
        Broadcaster.register(WithdrawAddressHomeCoordinatorProtocol.self, observer: self)
        Broadcaster.register(WithdrawAddressHomeStateManagerProtocol.self, observer: self)
    }
}

extension WithdrawAddressHomeCoordinator: WithdrawAddressHomeCoordinatorProtocol {
    func openWithDrawAddressVC() {
        let vc = R.storyboard.account.withdrawAddressViewController()!
        let coor = WithdrawAddressCoordinator(rootVC: self.rootVC)
        vc.coordinator = coor
        if let viewModel = self.state.selectedViewModel.value {
            vc.asset = viewModel.viewModel.model.id
        }
        self.rootVC.pushViewController(vc, animated: true)
    }
}

extension WithdrawAddressHomeCoordinator: WithdrawAddressHomeStateManagerProtocol {
    var state: WithdrawAddressHomeState {
        return store.state
    }

    func fetchData() {
        AppService.request(target: AppAPI.withdrawList, success: { (json) in
            let list = JSON(json).arrayValue.compactMap({ Trade.deserialize(from: $0.dictionaryObject) })
            self.store.dispatch(FecthWithdrawIds(data: list))
        }, error: { (_) in

        }) { (_) in

        }
    }

    func fetchAddressData() {
        guard self.state.data.value.count > 0 else { return }

        var data: [String: [WithdrawAddress]] = [:]

        for viewmodel in self.state.data.value {
            data[viewmodel.model.id] = AddressManager.shared.getWithDrawAddressListWith(viewmodel.model.id)
        }

        DispatchQueue.main.async {
            self.store.dispatch(WithdrawAddressHomeAddressDataAction(data: data))
        }
    }

    func selectCell(_ index: Int) {
        self.store.dispatch(WithdrawAddressHomeSelectedAction(index: index))
    }
}
