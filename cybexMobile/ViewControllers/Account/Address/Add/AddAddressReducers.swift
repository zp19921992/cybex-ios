//
//  AddAddressReducers.swift
//  cybexMobile
//
//  Created DKM on 2018/8/14.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift

func AddAddressReducer(action:Action, state:AddAddressState?) -> AddAddressState {
    return AddAddressState(isLoading: loadingReducer(state?.isLoading, action: action), page: pageReducer(state?.page, action: action), errorMessage: errorMessageReducer(state?.errorMessage, action: action), property: AddAddressPropertyReducer(state?.property, action: action))
}

func AddAddressPropertyReducer(_ state: AddAddressPropertyState?, action: Action) -> AddAddressPropertyState {
    var state = state ?? AddAddressPropertyState()
    
    switch action {
    default:
        break
    }
    
    return state
}



