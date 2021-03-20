//
//  ContentView.swift
//  NetCombine
//
//  Created by west on 17/03/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = TradeNewsViewModel()
    
    var body: some View {
        ScrollView{
            ForEach(viewModel.list){ item in
                Text(item.content)
                    .lineLimit(2)
                    .padding()
            }
        }
        .onAppear{
            viewModel.getNewsList()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
