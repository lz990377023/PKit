//
//  PLAudioRecorder.swift
//  PLKit
//
//  Created by Plumk on 2020/11/27.
//  Copyright © 2020 Plumk. All rights reserved.
//

import Foundation
import AVFoundation

class PLAudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    struct _Error: LocalizedError {
        let message: String
        
        var localizedDescription: String {
            return self.message
        }
        
    }
    
    /// 完成回调返回结果
    enum Result {
        case ok
        
        /// 取消录音
        case cancel
        
        /// 无权限
        case noPermission
        
        /// 存在其它录音model
        case exist
        
        /// 发生错误
        case error(err: Error)
    }
    
    /// 录音格式
    enum Format {
        case aac
        
        var suffix: String {
            switch self {
            case .aac:
                return "m4a"
            }
        }
    }
    
    
    static let shared = PLAudioRecorder()
    
    private let queue = DispatchQueue(label: "PLAudioRecorder")
    
    private var recordTickCount = 0
    private var recordTimer: Timer?
    private var audioRecorder: AVAudioRecorder?
    
    /// 当前录音中的model
    private(set) weak var model: RecordModel?
    
    /// 记录录音之前的session状态
    private var preCategory: AVAudioSession.Category?
    
    /// 开始录音
    /// - Parameter model:
    fileprivate func start(_ model: RecordModel) {
        
        /// 请求权限
        if AVAudioSession.sharedInstance().recordPermission == .undetermined {
            model.recordIsContinue = true
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                DispatchQueue.main.async {
                    if model.recordIsContinue {
                        self.start(model)
                    } else {
                        model.completeCallback?(model, .cancel)
                    }
                }
            }
            return
        }
        
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            /// 无麦克风权限
            model.completeCallback?(model, .noPermission)
            return
        }
        
        
        self.queue.async {
            
            guard self.model?.isRecording ?? false == false else {
                model.completeCallback?(model, .exist)
                return
            }
            
            
            
            var settings: [String: Any]!
            switch model.format {
            case .aac:
                settings = [AVSampleRateKey: 22050,
                            AVFormatIDKey: kAudioFormatMPEG4AAC,
                            AVLinearPCMBitDepthKey: 16,
                            AVNumberOfChannelsKey: 1]
                
            default:
                break
            }
            
            
            let session = AVAudioSession.sharedInstance()
            do {
                
                if session.category != .playAndRecord || session.category != .record {
                    self.preCategory = session.category
                    try session.setCategory(.playAndRecord)
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                }
                self.audioRecorder = try AVAudioRecorder.init(url: URL.init(fileURLWithPath: model.path), settings: settings)
                self.audioRecorder?.delegate = self

                guard self.audioRecorder?.prepareToRecord() ?? false else {
                    model.completeCallback?(model, .error(err: _Error(message: "无法开始录制")))
                    return
                }
                
                guard self.audioRecorder?.record() ?? false else {
                    model.completeCallback?(model, .error(err: _Error(message: "无法开始录制")))
                    return
                }
                
                model.duration = 0
                model.volume = 0
                model.isRecording = true
                self.model = model
                
                self.recordTickCount = 0
                self.recordTimer = Timer.init(timeInterval: 0.1, target: self, selector: #selector(self.recordTimerTick(_:)), userInfo: nil, repeats: true)
                RunLoop.main.add(self.recordTimer!, forMode: .common)
                
            } catch {
                model.completeCallback?(model, .error(err: error))
            }
        }
    }
    
    @objc fileprivate func recordTimerTick(_ timer: Timer) {
        
        self.recordTickCount += 1
        if self.recordTickCount >= 10 {
            self.recordTickCount = 0
            
            defer {
                if let m = self.model {
                    if m.maximumDuration > 0 && m.duration >= m.maximumDuration {
                        self.stop(m)
                    }
                }
                
            }
            
            self.model?.duration += 1
            self.model?.durationChangeCallback?(self.model!.duration)
            
            if !(self.audioRecorder?.isMeteringEnabled ?? true) {
                self.audioRecorder?.isMeteringEnabled = true
            }
            
            self.audioRecorder?.updateMeters()
            if let power = self.audioRecorder?.peakPower(forChannel: 0) {
                let volume = min(1.0, max(0, (power + 160) / 160))
                self.model?.volume = volume
                self.model?.volumeChangeCallback?(volume)
            }
        }
    }
    
    fileprivate func stop(_ model: RecordModel) {
        self.queue.async {
            guard self.model == model || (self.model == nil && self.audioRecorder != nil) else {
                return
            }
            self.audioRecorder?.stop()
            self.audioRecorder = nil
            
            self.recordTimer?.invalidate()
            self.recordTimer = nil
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.audioRecorder = nil
        if let x = self.preCategory {
            try? AVAudioSession.sharedInstance().setCategory(x)
            self.preCategory = nil
        }
        
        self.model?.isRecording = false
        self.model?.completeCallback?(self.model!, flag ? .ok : .error(err: _Error.init(message: "录制失败")))
        self.model = nil
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        self.audioRecorder = nil
        
        if let x = self.preCategory {
            try?  AVAudioSession.sharedInstance().setCategory(x)
            self.preCategory = nil
        }
        
        self.model?.isRecording = false
        if error != nil {
            self.model?.completeCallback?(self.model!, .error(err: error!))
        } else {
            self.model?.completeCallback?(self.model!, .error(err: _Error.init(message: "录制失败")))
        }
        self.model = nil
    }
}


// MARK: - RecordModel
extension PLAudioRecorder {
    class RecordModel: NSObject {
        
        /// 录音时间改变回调
        typealias DurationChangeCallback = (Int)->Void
        
        /// 录音音量改变回调
        typealias VolumeChangeCallback = (Float)->Void
        
        /// 录音完成回调
        typealias CompleteCallback = (RecordModel, Result)->Void
        
        
        /// 碰到权限申请时 如果授权之后是否继续录制
        fileprivate var recordIsContinue: Bool = false
        
        /// 录音保存路径
        private(set) var path: String!
        
        /// 录音格式
        private(set) var format: Format!
        
        /// 最大录音时间 0不限制
        private(set) var maximumDuration: Int = 0
        
        /// 是否录制中
        @objc dynamic fileprivate(set) var isRecording: Bool = false
        
        /// 当前录音时间
        @objc dynamic fileprivate(set) var duration: Int = 0
        
        /// 当前音量 0-1
        @objc dynamic fileprivate(set) var volume: Float = 0
        
        
        var durationChangeCallback: DurationChangeCallback?
        var volumeChangeCallback: VolumeChangeCallback?
        var completeCallback: CompleteCallback?
        
        ///
        /// - Parameters:
        ///   - format:
        ///   - path: 不传则自动生成路径  NSTemporaryDirectory() + "/时间戳.aac"
        ///   - maximumDuration:
        init(format: Format, path: String? = nil, maximumDuration: Int = 0) {
            self.format = format
            self.maximumDuration = maximumDuration
            
            if let path = path {
                self.path = path
            } else {
                self.path = NSTemporaryDirectory() + "\(time(nil)).\(format.suffix)"
            }
        }

        func start() {
            PLAudioRecorder.shared.start(self)
        }
        
        func stop() {
            self.recordIsContinue = false
            PLAudioRecorder.shared.stop(self)
        }
        
        func clear() -> Bool {
            guard !self.isRecording else {
                return false
            }
            
            self.duration = 0
            try? FileManager.default.removeItem(atPath: self.path)
            return true
        }
    }
}
