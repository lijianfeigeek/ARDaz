//
//  ARContentView.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import SwiftUI

struct ARContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sceneScaleIndex = 1//AR 物体到比例

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
                        }
                    }

                    Text("Tap a plane to place models.")
                        .foregroundColor(.white)
                        .padding()
                        .background(.white.opacity(0.3))
                        .cornerRadius(10)

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
                    
                    HStack {
                        Spacer()

                        Button(action: startAudio, label: {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.black)
                                .padding()
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
        do{
            let speechToTextModel = try SpeechToTextModel()
            DispatchQueue.global(qos: .userInitiated).async {
                do{
                    try speechToTextModel.startRecognition()
                    speechToTextModel.onRecognitionResult = { message in
                        // 更新 UI 或进行其他处理
                        print("更新UI: \(message)")
                        DispatchQueue.main.async {
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

#Preview {
    ARContentView()
}
