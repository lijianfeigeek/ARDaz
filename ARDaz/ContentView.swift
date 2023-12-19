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
    @State  var showARView = false
    var body: some View {
        VStack {
            QRCodeScannerExampleView(showErrorToast: $showErrorToast,showSuccessToast:$showSuccessToast,showARView: $showARView)
            .toast(isPresenting: $showSuccessToast) {
                AlertToast(type: .regular, title: "ARDaz will coming...")
            }
            .toast(isPresenting: $showErrorToast) {
                AlertToast(type: .error(.red), title: "QR code error")
            }
        }
        .fullScreenCover(isPresented: $showARView, content: {
            ARContentView()
                .onDisappear {
                    showARView = false
                }
        })
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
    @Binding var showARView:Bool

    @State private var scannedCode: String?
    
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 10) {
            
            Button("Scan DazAR QR Code") {
                isPresentingScanner = true
            }
            
            Text("Scan a DazAR QR code to begin")
        }
        .fullScreenCover(isPresented: $isPresentingScanner) {
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
                        let unzipPath = NSTemporaryDirectory()+UUID().uuidString
//                        SSZipArchive.unzipFile(atPath: task.filePath, toDestination: unzipPath)
                        SSZipArchive.unzipFile(atPath: task.filePath, toDestination: unzipPath, progressHandler: nil) { filePath, success, Error in
                            if(success){
                                let fileManager = FileManager.default
                                if fileManager.fileExists(atPath: filePath) {
                                    print("模型文件解压完成")
                                    do {
                                            let fileManager = FileManager.default
                                            let items = try fileManager.contentsOfDirectory(atPath: unzipPath)
                                            
                                            for item in items {
                                                let modelath = unzipPath+"/"+item
                                                DazModelSingleton.shared.modelPath = modelath
                                                print("模型文件="+modelath)
                                            }
                                        } catch {
                                            showErrorToast.toggle()
                                            print("Error while enumerating files \(unzipPath): \(error.localizedDescription)")
                                        }
                                    
                                    // 加载模型
                                    showARView = true
                                } else {
                                    print("模型文件不存在")
                                }
                            }else{
                                print("解压失败")
                            }
                            
                        };
                        
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

class DazModelSingleton {
    static let shared = DazModelSingleton()
    public var modelPath:String
    public var chatList:[String]

    private init() {
        // 私有化构造函数以防止外部实例化
        modelPath = "" // 提供一个初始值
        chatList = []
    }

    // 在这里添加类的方法和属性
}


#Preview {
    ContentView()
}
