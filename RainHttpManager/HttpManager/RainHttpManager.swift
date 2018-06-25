//
//  RainHttpManager.swift
//  RainHttpManager
//
//  Created by rainedAllNight on 2018/5/10.
//  Copyright © 2018年 luowei. All rights reserved.
//

import Foundation
import Moya
import Result
import SwiftyJSON
import ObjectMapper

// request auth type
public enum AuthType {
    case basic
    case user
}

//提供了三种调用和回调的方式，分别是 JSON(SwiftJSON)、model(Mappable, Codable)、modelList(Mappable, Codable), 可以根据需求自由选择
public typealias ModelSuccess<M> = (_ response: M?) -> ()
public typealias ListSuccess<M> = (_ response: [M]?) -> ()
public typealias JSONSuccess = (_ response: JSON?) -> ()
public typealias Failure = (RainHttpError) -> ()
fileprivate typealias Success = (_ response: RainHttpResponse?) -> ()

///请求基类
public class RainHttpManager<RainTarget: TargetType, M> {
    
    public var requestTasks = [URLRequest]()
    
    // MARK: - private method
    
    /// 基础请求方法
    ///
    /// - Parameters:
    ///   - target: TargetType
    ///   - authType: 授权方式
    ///   - success: 成功
    ///   - failure: 失败
    fileprivate class func request(_ target: RainTarget, authType: AuthType = .user, success: Success? = nil, failure: Failure? = nil) {
        let completion = {(result: Result<Moya.Response, MoyaError>) in
            switch result {
            case let .success(response):
                let responseData = RainHttpResponse(response.data)
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    success?(responseData)
                } catch {
                    failure?(responseData.error)
                }
                
            case let .failure(error):
                if let data = error.response?.data {
                    let responseData = RainHttpResponse(data)
                    failure?(responseData.error)
                } else {
                    failure?(RainHttpError.other(message: error.localizedDescription, code: (error as NSError).code))
                }
            }
        }
        
        let provider = getProvider(authType)
        provider.request(target, completion: completion)
    }
    
    /// 获取 MoyaProvider
    ///
    /// - Parameter authType: 授权方式
    /// - Returns: MoyaProvider
    fileprivate class func getProvider(_ authType: AuthType = .user) -> MoyaProvider<RainTarget> {
        let providerParameter = HttpProviderParameter<RainTarget>(authType)
        let provider = MoyaProvider<RainTarget>(endpointClosure: providerParameter.endpointClosure, requestClosure: providerParameter.requestClosure, stubClosure: providerParameter.stubClosure, callbackQueue: nil, manager: .default, plugins: providerParameter.plugins, trackInflights: false)
        return provider
    }
}

extension RainHttpManager where M == JSON {
    
    /// JSON回调的方式请求数据(注意此处的JSON是SwiftJSON库中的JSON struct)
    ///
    /// - Parameters:
    ///   - target: TargetType
    ///   - authType: 授权类型
    ///   - success: 成功
    ///   - failure: 失败
    public class func requestJSON(_ target: RainTarget, authType: AuthType = .user, success: JSONSuccess? = nil, failure: Failure? = nil) {
        self.request(target, authType: authType, success: { (response) in
            success?(response?.json)
        }) { (error) in
            failure?(error)
        }
    }
}

extension RainHttpManager where M: Mappable {
    
    /// model回调的方式请求数据
    ///
    /// - Parameters:
    ///   - target: TargetType
    ///   - authType: 授权类型
    ///   - success: 成功
    ///   - failure: 失败
    public class func requestModel(_ target: RainTarget, authType: AuthType = .user, success: ModelSuccess<M>? = nil, failure: Failure? = nil) {
        self.request(target, authType: authType, success: { (response) in
            do {
                let model: M? = try response?.mapToObject()
                success?(model)
            } catch let RainHttpError.jsonToDictionaryFailed(message) {
                failure?(RainHttpError.jsonToDictionaryFailed(message: message))
            } catch {
                #if Debug
                fatalError("未知错误")
                #endif
            }
            
        }) { (error) in
            failure?(error)
        }
    }
    
    /// modelList回调的方式请求数据
    ///
    /// - Parameters:
    ///   - target: TargetType
    ///   - authType: 授权类型
    ///   - success: 成功
    ///   - failure: 失败
    public class func requestModelList(_ target: RainTarget, authType: AuthType = .user, success: ListSuccess<M>? = nil, failure: Failure? = nil) {
        self.request(target, authType: authType, success: { (response) in
            do {
                let models: [M]? = try response?.mapToObjectArray()
                success?(models)
            } catch let RainHttpError.jsonToDictionaryFailed(message) {
                failure?(RainHttpError.jsonToDictionaryFailed(message: message))
            } catch {
                #if Debug
                fatalError("未知错误")
                #endif
            }
            
        }) { (error) in
            failure?(error)
        }
    }
}

// 或者你也可以使用codable的方式解析json，方式和ObjectMapper类似
extension RainHttpManager where M: Codable {
//    public class func requestModel(_ target: RainTarget, authType: AuthType = .user, success: ModelSuccess<M>? = nil, failure: Failure? = nil) {
//        self.request(target, authType: authType, success: { (response) in
//            do {
//                let model: M? = try response?.decodeToModel()
//                success?(model)
//            } catch {
//
//            }
//
//        }) { (error) in
//            failure?(error)
//        }
//    }
}

/// MoyaProvider
public struct HttpProviderParameter<RainTarget: TargetType> {
    
    fileprivate var authType: AuthType = .user
    
    init(_ authType: AuthType) {
        self.authType = authType
    }
    
    // endpoint
    var endpointClosure = {(target: RainTarget) -> Endpoint<RainTarget> in
        // 可以在此处统一配置header，或者通过manager的方式配置
        let headers = ["Access-Token": "token"]
        return Endpoint<RainTarget>(url: URL(target: target).absoluteString,
                                    sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                                    method: target.method,
                                    task: target.task,
                                    httpHeaderFields: headers)
    }
    
    // request
    var requestClosure = {(endpoint: Endpoint<RainTarget>, closure: MoyaProvider.RequestResultClosure) in
        do {
            var urlRequest = try endpoint.urlRequest()
            urlRequest.timeoutInterval = 60
            closure(.success(urlRequest))
        } catch MoyaError.requestMapping(let url) {
            closure(.failure(MoyaError.requestMapping(url)))
        } catch MoyaError.parameterEncoding(let error) {
            closure(.failure(MoyaError.parameterEncoding(error)))
        } catch {
            closure(.failure(MoyaError.underlying(error, nil)))
        }
    }
    
    // manager
    //    var manager: Manager {
    //        get {
    //            //通过session configuration的方式配置header
    //            let configuration = URLSessionConfiguration.default
    //            configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
    //            if self.authType == .user {
    //                configuration.httpAdditionalHeaders?["Access-Token"] = KYXUserModel.share.accessToken
    //            }
    //            let manager = Manager(configuration: configuration)
    //            manager.startRequestsImmediately = false
    //            return manager
    //            //        let alamofireManager = MoyaProvider<RainTarget>.defaultAlamofireManager()
    //            //        return alamofireManager
    //        }
    //    }
    
    // stub
    var stubClosure = { (target: RainTarget) -> StubBehavior in
        return .never
    }
    
    // plugins
    var plugins: [PluginType] {
        get {
            let hudPlugin = NetworkHUDPlugin<RainTarget>()
            #if DEBUG
            return [hudPlugin, NetworkLoggerPlugin<RainTarget>()]
            #else
            return [hudPlugin]
            #endif
        }
    }
}

// hud plugin(hud提示, 可根据项目自由配置,这里先注释掉)
private final class NetworkHUDPlugin<RainTarget: TargetType>: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        guard let topViewController = UIApplication.shared.keyWindow?.visibleViewController else {
            return
        }
        //        topViewController.showProgressHUD()
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        guard let topViewController = UIApplication.shared.keyWindow?.visibleViewController else {
            return
        }
        topViewController.dismissHUD()
    }
}

// networkLogger plugin(请求debug log)
private final class NetworkLoggerPlugin<RainTarget: TargetType>: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        let requestLogString = """
        NetworkRequestLogger:
        Url: \(request.request?.url?.absoluteString ?? "空")
        Method: \(target.method)
        Parameter: \(target.task)
        Header: \(request.request?.allHTTPHeaderFields ?? [:])
        """
        print(requestLogString)
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        var responseLogString = """
        NetworkResponseLogger:
        """
        switch result {
        case .success(let response):
            do {
                let successResponse = try response.filterSuccessfulStatusCodes()
                let jsonData = JSON(successResponse.data)["data"]
                let successLogString = """
                
                StatusCode: "\(response.statusCode)"
                RquestSuccesseData: "\(jsonData)"
                """
                print(successLogString)
            } catch {
                let jsonData = JSON(response.data)
                let errCode = jsonData["code"].intValue
                let errMsg = jsonData["msg"].stringValue
                let failureLogString = """
                StatusCode: "\(errCode)"
                ErrorCode: "\(errMsg)"
                """
                print(failureLogString)
            }
            
        case .failure(let error):
            var failureLogString = """
            ErrorCode: "\((error as NSError).code)"
            ErrorMsg: "\(error.localizedDescription)"
            """
            if let errorData = error.response?.data {
                failureLogString += """
                ErrorResponseData: "\(errorData)"
                """
            }
            responseLogString += failureLogString
        }
        
        print("\(responseLogString)\n")
    }
}

// request header plugin
private final class RequestHeaderPlugin<RainTarget: TargetType>: PluginType {
    
    fileprivate var authType: AuthType = .user
    
    init(_ authType: AuthType) {
        self.authType = authType
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        var headers = ["commonKey": "commonValue"]
        
        switch self.authType {
        case .user:
            headers["userKey"] = "userValue"
        case .basic:
            headers["basicKey"] = "basicValue"
        }
        
        request.allHTTPHeaderFields = headers
        return request
    }
}

public extension TargetType {
    //默认参数类型
    func defaultEcodingRequestTaskWith(parameters: [String: Any?]) -> Task {
        // 过滤parameters中value=nil的参数
        var filterOptionalParameters = [String: Any]()
        parameters.forEach {
            if let any = $1 {
                filterOptionalParameters[$0] = any
            }
        }
        
        return Task.requestParameters(parameters: filterOptionalParameters, encoding: URLEncoding.default)
    }
    
    // MARK: - 通用参数统一处理
    
    var baseURL: URL {
        return URL(string:"your baseURL")!
    }
    
    var headers : [String : String]? {
        return nil
    }
    
    // moya提供的stubs功能，暂时不使用
    var sampleData : Data {
        return Data()
    }
}



