//
//  ContentView.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import SwiftUI
import CodeScanner
import AlertToast

struct ContentView: View {
    @State  var showErrorToast = false
    @State  var showSuccessToast = false
    var body: some View {
        VStack {
            QRCodeScannerExampleView(showErrorToast: $showErrorToast,showSuccessToast:$showSuccessToast)
            .toast(isPresenting: $showSuccessToast) {
                AlertToast(type: .regular, title: "ARDaz will coming...")
            }
            .toast(isPresenting: $showErrorToast) {
                AlertToast(type: .error(.red), title: "QR code error")
            }
        }
        .padding()
    }
}

struct QRCodeScannerExampleView: View {
    @State private var isPresentingScanner = false
    
    @Binding var showErrorToast: Bool
    @Binding var showSuccessToast: Bool

    @State private var scannedCode: String?
    
    var body: some View {
        VStack(spacing: 10) {
            
            Button("Scan DazAR QR Code") {
                isPresentingScanner = true
            }
            
            Text("Scan a DazAR QR code to begin")
        }
        .sheet(isPresented: $isPresentingScanner) {
            CodeScannerView(codeTypes: [.qr]) { response in
                switch response {
                case .success(let result):
                    scannedCode = result.string
                    print("Found code: \(result.string)")
                    // 下载模型
                    isPresentingScanner = false
                    showSuccessToast.toggle()

                case .failure(let error):
                    print(error.localizedDescription)
                    isPresentingScanner = false
                    showErrorToast.toggle()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
