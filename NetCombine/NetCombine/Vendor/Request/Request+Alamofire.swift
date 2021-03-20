//
//  Request+Alamofire.swift
//  NetCombine
//
//  Created by west on 18/03/21.
//

import Foundation
import Alamofire
import HandyJSON

public typealias RequestMethod = HTTPMethod
public typealias RequestParameter = Parameters
public typealias RequestParameterEncoding = Parameters

public typealias MapJSON = HandyJSON

//MARK: 请求总览入口
public enum Request { }

//MARK: 接口请求协议
public protocol RequestEntityType {
    var baseURL: URL { get } /* 基础域名  */
    var path: String { get } /* 请求路径  */
    var method: RequestMethod { get } /* 请求方式  */
    var headers: HTTPHeaders? { get } /* 请求头  */
    var parameters: RequestParameter? { get } /* 请求参数  */
    var parameterEncoding: ParameterEncoding { get } /* 参数编码类型  */
    func infoFill() -> (path:String,para:[String:Any]) /* 请求信息配置  */
}
/* 协议默认实现  */
extension RequestEntityType{
    var baseURL: URL { return URL.init(string: "https://crm.cnabke.com")! }
    var path: String { return infoFill().path }
    var method: RequestMethod { return .post }
    var headers: HTTPHeaders? { return  HTTPHeaders() }
    var parameters: [String: Any]? { return infoFill().para }
    var parameterEncoding: ParameterEncoding{ return JSONEncoding.default }
}

//MARK: 请求过滤器
fileprivate struct MyInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var tempRequest = urlRequest
        tempRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        tempRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        tempRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")
        tempRequest.timeoutInterval = 15
        
        completion(.success(tempRequest))
    }
}

//MARK: 组装请求
public extension RequestEntityType{
    static func mapRequest(api:Self) -> DataRequest {
       return AF.request(api.baseURL.appendingPathComponent(api.path),
                          method: api.method,
                          parameters: api.parameters,
                          encoding: api.parameterEncoding,
                          headers: api.headers,
                          interceptor: MyInterceptor(), requestModifier: nil)
   }
}

//MARK: 数据解析映射
public extension DataRequest{
    func mapModel<T: HandyJSON>(_ type: T.Type, block:@escaping (T) -> Void) {
        responseData(completionHandler: { (info) in
            /* 打印日志  */
            logResponseInfo(info: info)
            
            if let response = info.response, response.statusCode == 200, let data = info.data,
                let jsonString = String.init(data: data, encoding: .utf8),
                let model = JSONDeserializer<T>.deserializeFrom(json: jsonString){
                block(model)
            }else{
                let resultStr = "{\"code\":\"\(info.response?.statusCode ?? 999)\",\"msg\":\"网络请求失败\"}"
                let model = JSONDeserializer<T>.deserializeFrom(json: resultStr)!
                block(model)
            }            
        })
    }
}

//MARK: 请求日志
fileprivate func logResponseInfo(info:AFDataResponse<Data>){
    guard let request = info.request, let url = request.url else {
        return
    }
    let host = url.absoluteString
    print("🍋地址:" + host)
    print("🍑请求头:" + request.headers.description)
    if let data = request.httpBody,
        let dataStr = String.init(data: data, encoding: String.Encoding.utf8) {
        print("🥝参数:" + dataStr)
    }
    if let data = info.data,  let jsonString = String.init(data: data, encoding: .utf8){
        print("🍏结果:" + jsonString.prefix(10000))
    }else{
        print("🍎结果:\(info.description)")
    }
}

