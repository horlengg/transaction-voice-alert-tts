//
//  DependencyInjectionDemonstrate.swift
//  OpenAITextToSpeech
//
//  Created by Houleng.LY on 2/7/26.
//

import SwiftUI
import Swinject
import Combine


class DependencyInjector {
    static let shared = DependencyInjector()
    let container = Container()
    
    private init() {
        // Register Home VM
        container.register(HomeViewModel.self) { _ in HomeViewModel() }
        
        // Register Profile VM
        container.register(ProfileViewModel.self) { _ in ProfileViewModel() }
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        return container.resolve(type)!
    }
}

// --- HOME VIEW ---
class HomeViewModel: ObservableObject {
    @Published var title = "Home Screen"
}

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(viewModel.title)
                
                // Navigate using the Factory
                NavigationLink("Go to Profile") {
                    ViewFactory.makeProfileView()
                }
            }
        }
    }
}

// --- PROFILE VIEW ---
class ProfileViewModel: ObservableObject {
    @Published var username = "John Doe"
}

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    
    var body: some View {
        Text("Profile of \(viewModel.username)")
    }
}


struct ViewFactory {
    static func makeHomeView() -> some View {
        let vm = DependencyInjector.shared.resolve(HomeViewModel.self)
        return HomeView(viewModel: vm)
    }
    
    static func makeProfileView() -> some View {
        let vm = DependencyInjector.shared.resolve(ProfileViewModel.self)
        return ProfileView(viewModel: vm)
    }
}


#Preview {
    ViewFactory.makeHomeView()
}
