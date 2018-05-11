//
//  TestModel.swift
//  RainHttpManager
//
//  Created by rainedAllNight on 2018/5/10.
//  Copyright © 2018年 luowei. All rights reserved.
//

import Foundation
import ObjectMapper

struct TestModel: Mappable {
    
    var name: String = ""
    var age: Int = 0
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        name <- map["name"]
        age  <- map["age"]
    }
}

struct TestCodableModel: Codable {
    
}

