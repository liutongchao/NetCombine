//
//  TradeNewsViewModel.swift
//  NetCombine
//
//  Created by west on 18/03/21.
//
import Foundation

class ListModel<T:MapJSON>: MapJSON {
    var code = 0  /* 状态值 */
    var msg = "" /* 状态描述 */
    var data = [T]()
    
    required init() {}
    deinit { print("\(self) -- ListModel -- 释放")}
}



extension TradeNewsViewModel{
    struct NewsModel:MapJSON {
        struct ItemInfo : MapJSON, Identifiable{
            var id = 0
            var title = ""
            var content = ""
            
            var source = ""
            var author = ""

            var url = ""
            var readCount = 0
            
            var typeId = 0
            var typeName = ""
            var imgOss = ""
            
            var releaseTime: TimeInterval = 0
            
            var cellHeight  = 110.0
        }
    }
}

class TradeNewsViewModel: ObservableObject {
    @Published var list = [NewsModel.ItemInfo]()
}

extension TradeNewsViewModel{
    func getNewsList() {
        Request.News.mapRequest(api: .getNewsList)
            .mapModel(ListModel<NewsModel.ItemInfo>.self) { (info) in
                if info.code == 1{
                    self.list = info.data
                }
            }
    }
    
    func getQECodeStatus() {
        Request.Scan.mapRequest(api: .getScanType(uid: "abkCrmQRCodeId:71a709cd39014e31a9e19faff30e816b"))
            .mapModel(ListModel<NewsModel.ItemInfo>.self) { (info) in
                print(info)
            }
        
//        Request.ScanLogin.mapRequest(api: .getScanType(uid: "abkCrmQRCodeId:71a709cd39014e31a9e19faff30e816b"))
//            .mapModel(ListModel<NewsModel.ItemInfo>.self) { (info) in
//                print(info)
//            }
    }
}
