//
//  CircularRevealNavigationDemo.swift
//  OpenAITextToSpeech
//
//  Created by Houleng.LY on 5/7/26.
//
import SwiftUI
import Combine


enum Route: Hashable {
    case home
    case mobileTopUp
    case transfer
}


final class Router: ObservableObject {
    @Published var path = NavigationPath()
    
    func push(_ route: Route, animation: Animation = .easeInOut(duration: 1)) {
        withAnimation(animation) {
            path.append(route)
        }
    }
    
    func pop(animation: Animation = .easeInOut(duration: 1)) {
//        withAnimation(animation) {
//            if !path.isEmpty { path.removeLast() }
//        }
        if !path.isEmpty { path.removeLast() }
    }
    
    func popToRoot(animation: Animation = .easeInOut(duration: 1)) {
        withAnimation(animation) {
            path.removeLast(path.count)
        }
    }
}

struct ExploreNavigateAnimation: View {
    
    @Environment(\.locale) var locale
    @Namespace private var nameSpace
    @StateObject private var router = Router()
    var message = "Hello "
    @State private var language = "en"
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack {
                    
                    Text("[\(language)]") + Text("home_menu_mobile_top_up")
                    
                    Button("Toggle Language"){
                        withAnimation {
                            language = language == "en"
                                ? "km-KH"
                                : "en"
                        }
                    }
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 100)
                        .padding(40)
                    
                    HStack(spacing: 20) {
                
                        Button {
                            router.push(.transfer)
                        } label: {
                            Image(systemName:"globe")
                                .padding(20)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .matchedTransitionSource(
                            id: Route.transfer,
                            in: nameSpace
                        )
                    
                        Button {
                            router.push(.mobileTopUp)
                        } label: {
                            Image(systemName:"phone")
                                .padding(20)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .matchedTransitionSource(id: Route.mobileTopUp, in: nameSpace) { source in
                            print("runn")
                            return source
                        }
                    
                    }
                    
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
        .environmentObject(router)
        .environment(\.locale, Locale(identifier: language))
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .home:
            Text("Home")
        case .mobileTopUp:
            PinView()
                .navigationTransition(
                    .zoom(
                        sourceID: Route.mobileTopUp, in: nameSpace
                    )
                )
                .navigationBarBackButtonHidden()
            
        case .transfer:
            PinView()
                .navigationTransition(
                    .zoom(
                        sourceID: Route.transfer, in: nameSpace
                    )
                )
                .navigationBarBackButtonHidden()
        }
    }
}


#Preview {
    ExploreNavigateAnimation()
}
