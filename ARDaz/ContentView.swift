//
//  ContentView.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import SwiftUI
import CodeScanner
struct ContentView: View {
    var body: some View {
        VStack {
            QRCodeScannerExampleView()
        }
        .padding()
    }
}

struct QRCodeScannerExampleView: View {
    @State private var isPresentingScanner = false
    @State private var scannedCode: String?
    
    var body: some View {
        VStack(spacing: 10) {
            
            Button("Scan Code") {
                isPresentingScanner = true
            }
            
            Text("Scan a QR code to begin")
        }
        .sheet(isPresented: $isPresentingScanner) {
            CodeScannerView(codeTypes: [.qr]) { response in
                switch response {
                case .success(let result):
                    scannedCode = result.string
                    print("Found code: \(result.string)")
                    isPresentingScanner = false
                case .failure(let error):
                    print(error.localizedDescription)
                    isPresentingScanner = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
