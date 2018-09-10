//
//  ETOCrowdViewController.swift
//  cybexMobile
//
//  Created koofrank on 2018/8/30.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift

class ETOCrowdViewController: BaseViewController {

	var coordinator: (ETOCrowdCoordinatorProtocol & ETOCrowdStateManagerProtocol)?

    @IBOutlet var contentView: ETOCrowdView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupData()
        setupUI()
        setupEvent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func refreshViewController() {
        
    }
    
    func setupUI() {
        self.contentView.actionButton.isEnabled = false
    }

    func setupData() {
        self.coordinator?.fetchData()
        self.coordinator?.fetchUserRecord()
        self.coordinator?.fetchFee()
    }
    
    func setupEvent() {
        NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidBeginEditing, object: self.contentView.titleTextView.textField, queue: nil) {[weak self] (notifi) in
            guard let `self` = self else { return }
            
            self.coordinator?.unsetValidStatus()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidEndEditing, object: self.contentView.titleTextView.textField, queue: nil) {[weak self] (notifi) in
            guard let `self` = self, let amount = self.contentView.titleTextView.textField.text?.toDouble() else { return }
            
            self.coordinator?.checkValidStatus(amount)
        }
    }
    
    override func configureObserveState() {
        coordinator?.state.pageState.asObservable().subscribe(onNext: {[weak self] (state) in
            guard let `self` = self else { return }
            
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        
        coordinator?.state.data.asObservable().subscribe(onNext: {[weak self] (model) in
            guard let `self` = self, let model = model else { return }

            self.contentView.updateUI(model, handler: ETOCrowdView.adapterModelToETOCrowdView(self.contentView))
        }).disposed(by: disposeBag)
        
        coordinator?.state.userData.asObservable().subscribe(onNext: {[weak self] (model) in
            guard let `self` = self, let model = model, let project = self.coordinator?.state.data.value else { return }
            
            self.contentView.updateUI((projectModel:project, userModel:model), handler: ETOCrowdView.adapterModelToUserCrowdView(self.contentView))
        }).disposed(by: disposeBag)
        
        coordinator?.state.fee.asObservable().subscribe(onNext: {[weak self] (model) in
            if let `self` = self, let data = model, let feeInfo = app_data.assetInfo[data.asset_id], let feeAmount = data.amount.toDouble()?.string(digits: feeInfo.precision, roundingMode: .down) {
                self.contentView.priceLabel.text = feeAmount + " " + feeInfo.symbol.filterJade
            }
        }).disposed(by: disposeBag)
        
        coordinator?.state.validStatus.asObservable().subscribe(onNext: {[weak self] (status) in
            guard let `self` = self else { return }

            if case .notValid = status {
                self.contentView.actionButton.isEnabled = false
                self.contentView.errorView.isHidden = true
                return
            }
            
            if case .ok = status {
                self.contentView.errorView.isHidden = true
                self.contentView.actionButton.isEnabled = true
            }
            else {
                self.contentView.actionButton.isEnabled = false
                self.contentView.errorView.isHidden = false
                self.contentView.errorLabel.text = status.desc()
            }

        }).disposed(by: disposeBag)

    }
}

//MARK: - View Event
extension ETOCrowdViewController {
    @objc func ETOCrowdButtonDidClicked(_ data:[String: Any]) {
        self.view.endEditing(true)
        
        guard let price = self.contentView.titleTextView.textField.text?.toDouble() else { return }

        self.coordinator?.showConfirm(price)
    }
    
    override func returnEnsureAction() {
        guard let price = self.contentView.titleTextView.textField.text?.toDouble() else { return }
        
        self.coordinator?.joinCrowd(price, callback: { (data) in
            if String(describing: data) == "<null>" {
                self.showWaiting(R.string.localizable.eto_transfer_title.key.localized(), content: R.string.localizable.eto_transfer_content.key.localized(), time: 5)
            }
        })
    }
    
    override func ensureWaitingAction(_ sender: CybexWaitingView) {
        ShowToastManager.shared.hide(0)
        self.navigationController?.popViewController()
    }
}

