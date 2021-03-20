//
//  Modifier+Refreshable.swift
//  SUIDemo
//
//  Created by west on 29/01/21.
//

import SwiftUI

extension View{
    func addPullRefresh(refreshing: Binding<Bool>, loadover: Binding<Bool>, headerAction: @escaping () -> Void, footerAction: @escaping () -> Void) -> some View {
        modifier(RefreshableModifier(refreshing: refreshing, loadover: loadover, action: headerAction, footerAction: footerAction))
    }
}

extension ScrollView {
    
    public func fixFlickering() -> some View {
        
        return self.fixFlickering { (scrollView) in
            
            return scrollView
        }
    }
    
    public func fixFlickering<T: View>(@ViewBuilder configurator: @escaping (ScrollView<AnyView>) -> T) -> some View {
        
        GeometryReader { geometryWithSafeArea in
            GeometryReader { geometry in
                configurator(
                ScrollView<AnyView>(self.axes, showsIndicators: self.showsIndicators) {
                    AnyView(
                    VStack {
                        self.content
                    }
                    .padding(.top, geometryWithSafeArea.safeAreaInsets.top)
                    .padding(.bottom, geometryWithSafeArea.safeAreaInsets.bottom)
                    .padding(.leading, geometryWithSafeArea.safeAreaInsets.leading)
                    .padding(.trailing, geometryWithSafeArea.safeAreaInsets.trailing)
                    )
                }
                )
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

fileprivate struct RefreshableModifier:ViewModifier {
    @Binding var refreshing: Bool
    @Binding var loadover: Bool
    let action: () -> Void
    let footerAction: () -> Void

    func body(content: Content) -> some View {
        RefreshableScrollView(refreshing: $refreshing, loadover: $loadover, action: action, footerAction:footerAction) {
            content
        }
    }
}


fileprivate struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    
    @State private var footerFrozen: Bool = false

    @Binding var refreshing: Bool
    @Binding var loadover: Bool

    var threshold: CGFloat = 80
    let content: Content
    let action: () -> Void
    let footerAction: () -> Void

    init(height: CGFloat = 80, refreshing: Binding<Bool>, loadover: Binding<Bool>, action: @escaping () -> Void, footerAction: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.threshold = height
        self._refreshing = refreshing
        self._loadover = loadover
        self.action = action
        self.footerAction = footerAction
        self.content = content()

    }
    
    var body: some View {
        return VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()

                    VStack {
                        self.content
                        LoadoverView(loadover: $loadover)
                        MovingView(isBottom: true)
                    }.alignmentGuide(.top, computeValue: { d in (self.refreshing && self.frozen) ? -self.threshold : 0.0 })

                    SymbolView(height: self.threshold, loading: self.refreshing, frozen: self.frozen, rotation: self.rotation)
                }
            }
//            .fixFlickering()
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }
    
    func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            self.refreshLogicHeader(values: values)
            self.refreshLogicFooter(values: values)
        }
    }
    
    func refreshLogicHeader(values: [RefreshableKeyTypes.PrefData]) {
        // Calculate scroll offset
        let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
        let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero
                
        guard movingBounds.minY > fixedBounds.minY else {
            return
        }
        
        self.scrollOffset  = movingBounds.minY - fixedBounds.minY
        
        self.rotation = self.symbolRotation(self.scrollOffset)
        
        // Crossing the threshold on the way down, we start the refresh process
        if !self.refreshing && (self.scrollOffset > self.threshold && self.previousScrollOffset <= self.threshold) {
            self.refreshing = true
            self.action()
        }
        
        if self.refreshing {
            // Crossing the threshold on the way up, we add a space at the top of the scrollview
            if self.previousScrollOffset > self.threshold && self.scrollOffset <= self.threshold {
                self.frozen = true
            }
        } else {
            // remove the sapce at the top of the scroll view
            self.frozen = false
        }
        
        // Update last scroll offset
        self.previousScrollOffset = self.scrollOffset
    }

    
    func refreshLogicFooter(values: [RefreshableKeyTypes.PrefData]) {
        let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero
        let bottomBounds = values.first { $0.vType == .bottomView }?.bounds ?? .zero
        
//        print("movingBounds:\(movingBounds)")
//        print("fixedBounds:\(fixedBounds)")
//        print("bottomBounds:\(bottomBounds)")
//        print("fixedBounds.maxY:\(fixedBounds.maxY)")
//        print("bottomBounds.maxY:\(bottomBounds.maxY)")
        
        guard bottomBounds.maxY > fixedBounds.minY else {
            return
        }
        if bottomBounds.maxY > fixedBounds.maxY{
            self.footerFrozen = false
        }
        guard self.footerFrozen == false else {
            return
        }
        if bottomBounds.maxY < fixedBounds.maxY{
            self.footerFrozen = true
            self.footerAction()
        }
    }
    
    func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        
        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        if scrollOffset < self.threshold * 0.60 {
            return .degrees(0)
        } else {
            // Calculate rotation, based on the amount of scroll offset
            let h = Double(self.threshold)
            let d = Double(scrollOffset)
            let v = max(min(d - (h * 0.6), h * 0.4), 0)
            return .degrees(180 * v / (h * 0.4))
        }
    }
    
    struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var frozen: Bool
        var rotation: Angle
        
        
        var body: some View {
            Group {
                if self.loading { // If loading, show the activity control
                    VStack {
                        Spacer()
                        ActivityRep()
                        Spacer()
                    }.frame(height: height).fixedSize()
                        .offset(y: -height + (self.loading && self.frozen ? height : 0.0))
                } else {
                    Image(systemName: "arrow.down") // If not loading, show the arrow
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                        .padding(height * 0.375)
                        .rotationEffect(rotation)
                        .offset(y: -height + (loading && frozen ? +height : 0.0))
                }
            }
        }
    }
    
    struct MovingView: View {
        var isBottom = false
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: isBottom ? .bottomView: .movingView, bounds: proxy.frame(in: .global))])
            }.frame(height: 0)
        }
    }
    
    
    struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .fixedView, bounds: proxy.frame(in: .global))])
            }
        }
    }
    
    struct LoadoverView: View {
        @Binding var loadover:Bool
        var body: some View {
            Group{
                if self.loadover{
                    Text("加载完毕")
                }
            }
        }
    }
}

fileprivate struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
        case bottomView
    }

    struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }

    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}

fileprivate struct ActivityRep: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<ActivityRep>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityRep>) {
        uiView.startAnimating()
    }
}

