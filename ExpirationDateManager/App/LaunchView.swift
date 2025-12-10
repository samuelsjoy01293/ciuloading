//
//  LaunchView.swift
//  ExpirationDateManager
//
//  Created by Ashot on 10.12.25.
//

import SwiftUI

struct LaunchView: View {
    
    @StateObject private var controller = AccessController()
    @State private var remoteURL: URL?
    @State private var showLoader = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            if remoteURL == nil && !showLoader {
                MainTabView()
            }
            
            if let u = remoteURL {
                
                SecureWebView(url: u, loading: $showLoader)
                    .edgesIgnoringSafeArea(.all)
                    .statusBar(hidden: true)
                    .onAppear {
                        OrientationManager.shared.set(.all)   
                    }
                
            }
            
            if showLoader {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.8)
                    )
            }
        }
        .onReceive(controller.$current) { status in
            switch status {
            case .validating:
                showLoader = true
                print(status)
            case .approved(_, let url):
                remoteURL = URL(string:"https://www.google.com/")
                //                    url
                print("url",url)
                print(status)
                showLoader = false
            case .useNative:
                remoteURL = nil
                showLoader = false
                print(status)
            case .idle:
                break
            }
        }
        .onAppear {
            showLoader = true
            controller.beginCheck()
        }
    }
}
