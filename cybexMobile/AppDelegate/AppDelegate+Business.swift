//
//  AppDelegate+Configration.swift
//  cybexMobile
//
//  Created by koofrank on 2018/12/11.
//  Copyright © 2018 Cybex. All rights reserved.
//

import Foundation
import Reachability
import RxSwift

extension AppDelegate {
    func requestSetting() {
        monitorNetworkOfSetting()

        AssetConfiguration.shared.whiteListOfIds.asObservable().skip(1).subscribe(onNext: { (_) in
            MarketConfiguration.shared.fetchMarketPairList()
        }).disposed(by: disposeBag)

        MarketConfiguration.shared.marketPairs.asObservable().skip(1).subscribe(onNext: { (_) in
            AppConfiguration.shared.startFetchOuterPrice()
        }).disposed(by: disposeBag)

        CybexWebSocketService.shared.canSendMessageReactive.skip(1).asObservable().subscribe(onNext: { (_) in
            if CybexConfiguration.shared.chainID.value.isEmpty {
                CybexConfiguration.shared.getChainId()
            }
        }).disposed(by: disposeBag)

        Observable.combineLatest(
            MarketConfiguration.shared.marketPairs.skip(1).asObservable(),
            CybexWebSocketService.shared.canSendMessageReactive.skip(1).asObservable()
            ).subscribe(onNext: { (pairs, canSend) in

                if !pairs.isEmpty, canSend {
                    appCoodinator.getLatestData()
                }
            }).disposed(by: disposeBag)

        appData.assetNameToIds.skip(1).asObservable().subscribe(onNext: { (_) in
            TradeConfiguration.shared.fetchPairPrecision()
        }).disposed(by: disposeBag)
    }

    func monitorNetworkOfSetting() {
        //第一次会直接走回调
        if reachability.connection == .none {
            NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: nil, queue: nil) { (note) in
                guard let reachability = note.object as? Reachability else {
                    return
                }

                switch reachability.connection {
                case .wifi, .cellular:
                    self.checkSetting()
                case .none:

                    break
                }

            }
        }

        #if targetEnvironment(simulator) //模拟器第一次收不到 NetWorkChanged 通知
            self.checkSetting()
        #endif
        NotificationCenter.default.addObserver(forName: .NetWorkChanged, object: nil, queue: nil) { (note) in
            self.checkSetting()
        }
    }

    func checkSetting() {
        if AppConfiguration.shared.enableSetting.value == nil {
            AppConfiguration.shared.fetchAppEnableSettingRequest()
        }
        if AssetConfiguration.shared.whiteListOfIds.value.isEmpty {
            AssetConfiguration.shared.fetchWhiteListAssets()
        }

        if MarketConfiguration.shared.importMarketLists.value.isEmpty {
            MarketConfiguration.shared.fetchTopStickMarkets()
        }
        
        if AssetConfiguration.shared.quoteToProjectNames.value.isEmpty {
            AssetConfiguration.shared.fetchQuoteToProjectNames()
        }
    }
}
