//
//  ARContentView.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import SwiftUI
import ActivityIndicatorView
import Tiercel
import ZipArchive
struct ARContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sceneScaleIndex = 1//AR 物体到比例
    @State private var isSpeek = false
    @State private var showText = true // 控制 Text 的显示
    
    @ObservedObject var viewModel = ViewModel()

    private var sceneScale: SIMD3<Float> {
        AppConfig.sceneScales[sceneScaleIndex]
    }
    
    var body: some View {
        ARContainerView(sceneScale: sceneScale)
            .overlay {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }

//                    Text("Tap a plane to place models.")
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(.white.opacity(0.3))
//                        .cornerRadius(10)

                    Spacer()

//                    HStack {
//                        Spacer()
//
//                        Button(action: scaleChange, label: {
//                            Image(systemName: "plus.circle")
//                                .font(.system(size: 50))
//                                .padding()
//                        })
//                        Spacer()
//                    }
//                    
//                    HStack {
//                        Spacer()
//
//                        Button(action: scaleChange, label: {
//                            Image(systemName: "minus.circle")
//                                .font(.system(size: 50))
//                                .padding()
//                        })
//                        Spacer()
//                    }
                    
                    HStack{
                        Spacer()
                        ActivityIndicatorView(isVisible: $isSpeek, type: .scalingDots())
                            .frame(width: 100, height: 50)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()

                        Button(action: startAudio, label: {
                            if(isSpeek){
                                Image(systemName: "person.line.dotted.person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .padding()
                            }else{
                                Image(systemName: "person.wave.2")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        })
                        Spacer()
                    }
                    
                }
                .padding(40)
            }
    }
    
    private func scaleChange() {
        sceneScaleIndex = sceneScaleIndex == AppConfig.sceneScales.count - 1
                            ? 0 : sceneScaleIndex + 1
    }
    
    private func startAudio(){
        isSpeek.toggle()
        do{
            let speechToTextModel = try SpeechToTextModel()
            DispatchQueue.global(qos: .userInitiated).async {
                do{
                    try speechToTextModel.startRecognition()
                    speechToTextModel.onRecognitionResult = { message_org in
                        let url = "http://30.176.204.45:8888/sneaker_pegasustrail.usdz.zip"
                        var message:String
                        if message_org.contains(url) {
                            print("包含")
                            let splitString = message_org.split(separator: url, omittingEmptySubsequences: false)
                            message = String(splitString[0])
                            DispatchQueue.main.async{
                                // 更新AR模型
                                // 下载模型文件,解压，mdt5校验，保存到本地，加载模型
                                viewModel.sessionManager = Tiercel.SessionManager("ARContentView", configuration: SessionConfiguration())
                                viewModel.task = viewModel.sessionManager!.download(url)
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
                                                            // 发送通知 更新模型
                                                            NotificationCenter.default.post(name:.myCustomNotification, object: nil, userInfo: nil)
                                                        }
                                                    } catch {
//                                                        showErrorToast.toggle()
                                                        print("Error while enumerating files \(unzipPath): \(error.localizedDescription)")
                                                    }
                                                
                                                // 加载模型
//                                                showARView = true
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
                            }

                        } else {
                            print("不包含")
                            message = message_org
                        }
                        // 更新 UI 或进行其他处理
                        print("更新UI: \(message)")
                        DispatchQueue.global(qos: .userInitiated).async {
                            speechToTextModel.synthesisToSpeaker(inputText: message)
                        }
                        DispatchQueue.main.async {
                            isSpeek.toggle()

                            // TODO 如何展示下面的SWIFTUI View
                            UIApplication.shared.inAppNotification(adaptForDynamicIsland: true, timeout: 4, swipeToClose: true) { isDynamicIslandEnabled in
                                HStack {
                                    Image("Pic")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(.circle)
                                    
                                    VStack(alignment: .leading, spacing: 6, content: {
                                        Text("Daz")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                        
                                        Text(message)
                                            .textScale(.secondary)
                                            .foregroundStyle(.gray)
                                    })
                                    .padding(.top, 20)
                                    
                                    Spacer(minLength: 0)
                                    
                                    Button(action: {}, label: {
                                        Image(systemName: "speaker.slash.fill")
                                            .font(.title2)
                                    })
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.circle)
                                    .tint(.white)
                                }
                                .padding(15)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.black)
                                }
                            }
                        }
                    }
                }catch{
                    
                }
            }
        }catch{
            
        }
        
        
    }
}

extension Notification.Name {
    static let myCustomNotification = Notification.Name("myCustomNotification")
}

#Preview {
    ARContentView()
}
