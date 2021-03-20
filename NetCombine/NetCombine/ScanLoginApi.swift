//
//  ScanLoginViewModel.swift
//  NetCombine
//
//  Created by west on 19/03/21.
//

import Foundation
extension Request{
    enum Scans {
        enum Api {
            case getScanType(uid:String)
        }
        enum Path:String {
            case getType = "/crm/qrLogin/getScanType"
        }
    }
}
extension Request.Scans.Api: RequestEntityType{
    var baseURL: URL{
        return URL.init(string: "https://test-gateway.cnabke.com")!
    }
    func infoFill() -> (path: String, para: [String : Any]) {
        switch self {
        case .getScanType(uid: let uid):
            let para = ["uid":uid]
            return (Request.Scans.Path.getType.rawValue, para)
        }
    }
}
