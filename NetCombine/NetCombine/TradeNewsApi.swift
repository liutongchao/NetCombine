//
//  TradeNewsApi.swift
//  NetCombine
//
//  Created by west on 18/03/21.
//
import Foundation
extension Request{
    enum News {
        case getNewsList
        
        enum Path:String {
            case getNewsList = "/wap/app/news/selectNewsList.do"
        }
    }
}

extension Request.News : RequestEntityType{
    func infoFill() -> (path: String, para: [String : Any]) {
        switch self {
        case .getNewsList:
            return (Path.getNewsList.rawValue, ["":""])
        }
    }
}

////////
extension Request{
    enum Scan {
        case getScanType(uid:String)
        
        enum Path:String {
            case getScanType = "/crm/qrLogin/getScanType"
        }
    }
}

extension Request.Scan : RequestEntityType{
    var baseURL: URL{
        return URL.init(string: "https://test-gateway.cnabke.com")!
    }
    func infoFill() -> (path: String, para: [String : Any]) {
        switch self {
        case .getScanType(uid: let uid):
            let para = ["uid":uid]
            return (Request.Scan.Path.getScanType.rawValue, para)
        }
    }
}
