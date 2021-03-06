//
//  MyHistoryCoordinator.swift
//  cybexMobile
//
//  Created DKM on 2018/6/13.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift
import Reachability

protocol MyHistoryCoordinatorProtocol {
}

protocol MyHistoryStateManagerProtocol {
    var state: MyHistoryState { get }

    func disconnect()
    func fetchMyOrderHistory(_ pair: Pair, page: Int, callback: ((Bool) -> Void)?)
    func fetchAllMyOrderHistory(_ page: Int, callback: ((Bool) -> Void)?)

    func checkConnectStatus() -> Bool
    func connect()
    func reconnect()
}

class MyHistoryCoordinator: NavCoordinator {
    var store = Store<MyHistoryState>(
        reducer: myHistoryReducer,
        state: nil,
        middleware: [trackingMiddleware]
    )

    let service = OCOWebSocketService()

}

extension MyHistoryCoordinator: MyHistoryCoordinatorProtocol {

}

extension MyHistoryCoordinator: MyHistoryStateManagerProtocol {
    var state: MyHistoryState {
        return store.state
    }

    func reconnect() {
        service.reconnect()
    }

    func connect() {
        service.connect()
        monitorService()
    }

    func checkConnectStatus() -> Bool {
        return service.checkNetworConnected()
    }

    func fetchMyOrderHistory(_ pair: Pair, page: Int, callback: ((Bool) -> Void)?) {
        service.messageCanSend.delegate(on: self) { (self, _) in
            self.fetchMyOrderHistoryRequest(pair, page: page, callback: callback)
        }
        if service.checkNetworConnected() {
            self.fetchMyOrderHistoryRequest(pair, page: page, callback: callback)
        }else {
            service.reconnect()
        }
    }

    func maxOrderId(_ callback: @escaping (_ lessThanOrderId: String) -> Void) {
        let request = GetLimitOrderStatus(response: { result in
            if let result = result as? String {
                callback(result)
            }
        }, status: LimitOrderStatusApi.getMaxLimitOrderIdByTime(date: Date()))
        self.service.send(request: request)
    }

    func fetchMyOrderHistoryRequest(_ pair: Pair, page: Int, callback: ((Bool) -> Void)?) {
        guard let userId = UserManager.shared.account.value?.id else { return }


        maxOrderId {[weak self] (lessThanOrderId) in
            let request = GetLimitOrderStatus(response: { json in
                if let json = json as? [[String: Any]], let object = [LimitOrderStatus].deserialize(from: json) as? [LimitOrderStatus] {
                    callback?(object.count != 20)
                    self?.store.dispatch(FillOrderDataFetchedAction(data: object))
                }
            }, status: LimitOrderStatusApi.getMarketLimitOrder(userId: userId, asset1Id: pair.quote, asset2Id: pair.base, lessThanOrderId: lessThanOrderId, limit: 20))
            self?.service.send(request: request)
        }

    }

    func fetchAllMyOrderHistory(_ page: Int, callback: ((Bool) -> Void)?) {
        service.messageCanSend.delegate(on: self) { (self, _) in
            self.fetchAllMyOrderHistoryRequest(page, callback: callback)
        }
        if service.checkNetworConnected() {
            self.fetchAllMyOrderHistoryRequest(page, callback: callback)
        }else {
            service.reconnect()
        }
    }

    func fetchAllMyOrderHistoryRequest(_ page: Int, callback: ((Bool) -> Void)?) {
        guard let userId = UserManager.shared.account.value?.id else { return }

        maxOrderId {[weak self] (lessThanOrderId) in
            let request = GetLimitOrderStatus(response: { (json) in
                if let orders = json as? [[String: Any]], let object = [LimitOrderStatus].deserialize(from: orders) as? [LimitOrderStatus] {
                    callback?(object.count != 20)
                    self?.store.dispatch(FillOrderDataFetchedAction(data: object))
                }
            }, status: LimitOrderStatusApi.getLimitOrder(userId: userId, lessThanOrderId: lessThanOrderId, limit: 20))
            self?.service.send(request: request)
        }
    }

    func monitorService() {
        NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: nil, queue: nil) { (note) in
            guard let reachability = note.object as? Reachability else {
                return
            }
            switch reachability.connection {
            case .wifi, .cellular:
                self.service.reconnect()
            case .none:
                self.service.disconnect()
                break
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (note) in
            self.service.reconnect()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (note) in
            self.service.disconnect()
        }
    }

    func disconnect() {
        service.disconnect()
    }
}
