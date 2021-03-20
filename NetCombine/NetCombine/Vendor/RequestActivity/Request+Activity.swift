//
//  Request+Activity.swift
//  SUIDemo
//
//  Created by west on 28/01/21.
//

import SwiftUI

extension View{
    func addRequestActivity(isShow:Bool) -> some View {
        modifier(RequestActivity(isShow: isShow))
    }
}

fileprivate struct RequestActivity:ViewModifier {

    var isShow:Bool
    func body(content: Content) -> some View {
        content
            .overlay(RequestActivityView(isShow: isShow))
    }
}

fileprivate struct RequestActivityView:View {
    var isShow:Bool
    
    var body: some View{
        Group{
            CenterView(isShow: isShow)
                .opacity(isShow ? 1 : 0)
        }
    }
    
    struct CenterView:View {
        var isShow:Bool
        var body: some View{
            GeometryReader{ geomerty in
                VStack(alignment: .center){
                    Activity(startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 270), clockwise: false)
                        .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .red, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .miter))
                        .frame(width: 60, height: 60, alignment: .center)
                        .rotationEffect(Angle.init(degrees: isShow ? 0 : 360))
                        .animation( isShow ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: false) : .default)
//                        .animation( isShow ? Animation.easeInOut(duration: 1) : .default)

                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.gray, radius: 5, x: 0, y: 0)
                .position(x: geomerty.size.width / 2 , y: geomerty.size.height / 2)
            }
            .background(Color.init(Color.RGBColorSpace.sRGB, white: 1, opacity: 0.7))
            .ignoresSafeArea()
        }
    }
    
    struct Activity:Shape {
        var startAngle: Angle
        var endAngle: Angle
        var clockwise: Bool
        
        func path(in rect: CGRect) -> Path {
            print(rect)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = CGFloat(20)
            var p = Path()
            p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
            return p
        }
    }
}
