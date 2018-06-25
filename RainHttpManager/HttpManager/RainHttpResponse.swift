//
//  RainHttpResponse.swift
//  RainHttpManager
//
//  Created by rainedAllNight on 2018/5/10.
//  Copyright © 2018年 luowei. All rights reserved.
//

import Foundation
import SwiftyJSON
import ObjectMapper

/* 比如后台数据结构为
 - data: {数据}
 - msg:
 - code:
 */
public struct RainHttpResponse {
    
    var data: Data
    
    init(_ data: Data) {
        self.data = data
        if let jsonStr = self.json.rawString(), jsonStr.count <= 0 {
            self.error = RainHttpError.jsonSerializationFailed(message: "json解析失败")
        }
    }
    
    var json: JSON {
        return JSON(data)["data"]
    }
    
    var dictionary: [String: Any]? {
        let data = try? JSONSerialization.jsonObject(with: self.data, options: []) as? [String : Any]
        return data?!["data"] as? [String: Any]
    }
    
    var code: Int {
        return json["code"].intValue
    }
    
    var message: String {
        return json["msg"].stringValue
    }
    
    var error: RainHttpError {
        get {
            switch code {
            case ResponseCode.forceLogoutError:
                return RainHttpError.loginStateIsexpired(message: message, code: code)
            default:
                return RainHttpError.serverResponse(message: message, code: code)
            }
        }
        
        set {}
    }
}

extension RainHttpResponse {
    
    // MARK: - ObjectMapper方式解析
    
    func mapToObject<Model: Mappable>() throws -> Model? {
        guard let jsonString = self.json.rawString() else {
            print("your response json string is incorrect")
            throw RainHttpError.jsonToDictionaryFailed(message: "json转model失败")
        }
        
        return Mapper<Model>().map(JSONString: jsonString)
    }
    
    func mapToObjectArray<Model: Mappable>() throws -> [Model]? {
        guard let jsonString = self.json.rawString() else {
            print("your response json string is incorrect")
            throw RainHttpError.jsonToDictionaryFailed(message: "json转modelList失败")
        }
        
        let models = Mapper<Model>().mapArray(JSONString: jsonString)
        return models
    }
    
    // MARK: - Codable方式解析
    
    func decodeToObject<Model: Codable>() throws -> Model? {
        do {
            let model = try JSONDecoder().decode(Model.self, from: self.json.rawData())
            return model
        } catch  {
            return nil
        }
    }
    
    func decodeToObjectArray<Model: Codable>() throws -> [Model]? {
        do {
            let models = try JSONDecoder().decode([Model].self, from: self.json.rawData())
            return models
        } catch  {
            return nil
        }
    }
}
