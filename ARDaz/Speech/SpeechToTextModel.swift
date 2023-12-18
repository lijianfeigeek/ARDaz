//
//  SpeechToTextModel.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import Foundation
import AVFoundation
import MicrosoftCognitiveServicesSpeech
import Alamofire

class SpeechToTextModel {
    var audioEngine: AVAudioEngine
    var pushStream: SPXPushAudioInputStream
    var reco: SPXSpeechRecognizer
    var conversionQueue: DispatchQueue
    var speechConfig: SPXSpeechConfiguration
    var audioConfig: SPXAudioConfiguration
    var sampleRate: Int
    var bufferSize: Int
    var onRecognitionResult: ((String) -> Void)?
    
    init() throws {
        self.audioEngine = AVAudioEngine()
        self.conversionQueue = DispatchQueue(label: "conversionQueue")
        self.sampleRate = 16000
        self.bufferSize = 2048
        self.speechConfig = try SPXSpeechConfiguration(subscription: "fffcf41611b246eb988283df69ded060", region: "westeurope")
        self.speechConfig.speechRecognitionLanguage = "en-US"
        self.pushStream = SPXPushAudioInputStream()
        self.audioConfig = SPXAudioConfiguration(streamInput: pushStream)!
        self.reco = try SPXSpeechRecognizer(speechConfiguration: self.speechConfig, audioConfiguration: self.audioConfig)
    }

    func readDataFromMicrophone() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self.sampleRate), channels: 1, interleaved: false)

        guard let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)
        else {
            return
        }
        // Install a tap on the audio engine with the buffer size and the input format.
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) { (buffer, time) in
                        
            self.conversionQueue.async { [self] in
                // Convert the microphone input to the recording format required
                let outputBufferCapacity = AVAudioFrameCount(buffer.duration * recordingFormat!.sampleRate)

                guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: outputBufferCapacity) else {
                    print("Failed to create new pcm buffer")
                    return
                }
                pcmBuffer.frameLength = outputBufferCapacity
                
                var error: NSError? = nil
                let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                formatConverter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
                
                if error != nil {
                    print(error!.localizedDescription)
                }
                else {
                    self.pushStream.write((pcmBuffer.data()))
                }
            }
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        }
        catch {
            print(error.localizedDescription)
        }
    }

    func startRecognition() throws {
        // 设置语音识别配置
        self.speechConfig.speechRecognitionLanguage = "en-US"
        self.speechConfig.endpointId = "https://westeurope.api.cognitive.microsoft.com/"

        // 创建和配置音频流
        self.pushStream = SPXPushAudioInputStream()
        self.audioConfig = SPXAudioConfiguration(streamInput: pushStream)!
        self.reco = try SPXSpeechRecognizer(speechConfiguration: self.speechConfig, audioConfiguration: self.audioConfig)

        // 设置事件处理
        reco.addRecognizedEventHandler() { reco, evt in
            print("Final recognition result: \(evt.result.text ?? "(no result)")")
            // 可以在这里更新 UI 或调用其他方法处理识别结果
            // 发起网络请求
            let url = "http://8.209.213.28:8081/chat_completions"
            let chatContents = [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": evt.result.text]
            ]
            
            do {
                let data = try JSONSerialization.data(withJSONObject: chatContents, options: [])
                if let jsonChatContents = String(data: data, encoding: .utf8) {
                    let parameters = ["chat_contents": jsonChatContents]

                    AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
                        switch response.result {
                        case .success(let value):
                            print("Response: \(value)")
                            // 假设 responseData 是从服务器获取的数据
                            if let responseData = response.data {
                                do {
                                    if let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
                                       let message = jsonObject["response"] as? String {
                                        print("Received message: \(message)")
                                        
                                        // TODO 回调外层，给SWIFTUI
                                        DispatchQueue.main.async {
                                            self.onRecognitionResult?(message)
                                        }
                                    }
                                } catch {
                                    print("Error parsing JSON: \(error)")
                                }
                            }
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                print("JSON Serialization error: \(error.localizedDescription)")
            }
        }
        
        reco.addCanceledEventHandler { reco, evt in
            print("Recognition canceled: \(evt.errorDetails?.description ?? "(no result)")")
            // 可以在这里处理错误或更新 UI
        }

        // 开始识别
        try reco.recognizeOnceAsync({ srresult in
            // 停止音频引擎并关闭音频流
            self.stopRecognition()
            // 可以在这里处理识别完成后的逻辑
        })

        // 从麦克风读取数据
        try readDataFromMicrophone()
    }


    func stopRecognition() {
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.pushStream.close()
    }
}

extension AVAudioPCMBuffer {
    func data() -> Data {
        var nBytes = 0
        nBytes = Int(self.frameLength * (self.format.streamDescription.pointee.mBytesPerFrame))
        var range: NSRange = NSRange()
        range.location = 0
        range.length = nBytes
        let buffer = NSMutableData()
        buffer.replaceBytes(in: range, withBytes: (self.int16ChannelData![0]))
        return buffer as Data
    }
    
    var duration: TimeInterval {
        format.sampleRate > 0 ? .init(frameLength) / format.sampleRate : 0
    }
}

