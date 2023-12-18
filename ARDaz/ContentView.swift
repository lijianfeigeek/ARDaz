//
//  ContentView.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import SwiftUI
import CodeScanner
import AlertToast
import Tiercel
import ZipArchive
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

class ViewModel: ObservableObject {
    var sessionManager: Tiercel.SessionManager?
    var task: DownloadTask?

    // 初始化 sessionManager 和 task
    
    init(sessionManager: Tiercel.SessionManager? = nil, task: DownloadTask? = nil) {
        self.sessionManager = sessionManager
        self.task = task
    }
}

struct QRCodeScannerExampleView: View {
    @State private var isPresentingScanner = false
    
    @Binding var showErrorToast: Bool
    @Binding var showSuccessToast: Bool

    @State private var scannedCode: String?
    
    @ObservedObject var viewModel = ViewModel()
    
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
                    isPresentingScanner = false
                    showSuccessToast.toggle()
                    print("Found code: \(result.string)")
                    // 下载模型文件,解压，mdt5校验，保存到本地，加载模型
                    viewModel.sessionManager = Tiercel.SessionManager("CodeScannerView", configuration: SessionConfiguration())
                    viewModel.task = viewModel.sessionManager!.download(scannedCode!)
                    viewModel.sessionManager!.start(viewModel.task!)
                    viewModel.task!.progress(onMainQueue: true) { (task) in
                        let progress = task.progress.fractionCompleted
                        print("下载中, 进度：\(progress)")
                    }.success { (task) in
                        print("下载完成")
                        print(task.filePath)
                        let unzipPath = NSTemporaryDirectory()+"/model"
                        SSZipArchive.unzipFile(atPath: task.filePath, toDestination: unzipPath)
                        let fileManager = FileManager.default
                        // 模型位置
                        let filePath =  NSTemporaryDirectory()+"/model/daz.usdz"
                        if fileManager.fileExists(atPath: filePath) {
                            print("模型文件存在")
                            print(filePath)
                            // 加载模型
                            
                        } else {
                            print("模型文件不存在")
                        }
                        
                    }.failure { (task) in
                        print("下载失败")
                    }
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
