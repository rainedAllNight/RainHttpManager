//
//  TestApi.swift
//  RainHttpManager
//
//  Created by rainedAllNight on 2018/5/10.
//  Copyright © 2018年 luowei. All rights reserved.
//

import Foundation
import Moya

enum ApiTest {
    case fetchTestJSON
    case fetchTestModel
    case fetchTestModelList(pageIndex: Int, pageSize: Int)
}

extension ApiTest: TargetType {
    var path: String {
        switch self {
        case .fetchTestJSON:
            return "testJSON path"
        case .fetchTestModel:
            return "testModel path"
        
        case .fetchTestModelList(_, _):
            return "testModelList path"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var task: Task {
        switch self {
        case .fetchTestJSON:
            return defaultEcodingRequestTaskWith(parameters: ["testJSONParaKey": "paraValue"])
        case .fetchTestModel:
            return defaultEcodingRequestTaskWith(parameters: ["testModelParaKey": "paraValue"])
        
        case let .fetchTestModelList(pageIndex, pageSize):
            return defaultEcodingRequestTaskWith(parameters: ["pageIndex": pageIndex, "pageSize": pageSize])
        }
    }
}
