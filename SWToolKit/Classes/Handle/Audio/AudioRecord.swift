//
//  AudioRecord.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/4.
//

import Foundation
import AVFoundation


public extension AudioRecord {
    @objc enum AudioRecordFailType: Int{
        case timeShort = 1
    }
}


@objc public protocol AudioRecordDelegate {
    ///当前获取麦克风状态
    @objc optional func audioRecord(audioRecord:AudioRecord, audioAuthState:AVAuthorizationStatus) -> Void
    ///当前已经录制音频的时长 和 音量
    @objc optional func audioRecord(audioRecord:AudioRecord, recordingTime:TimeInterval, volum:Double) -> Void
    /// 录制完成后的文件地址
    @objc optional func audioRecord(audioRecord:AudioRecord, resultRecordPath:URL, recordTime:TimeInterval) -> Void
    /// 录制失败
    @objc optional func audioRecord(audioRecord:AudioRecord, failType:AudioRecord.AudioRecordFailType) -> Void
    /// 是否开始录制
    @objc optional func audioRecord(audioRecord:AudioRecord, start:Bool) -> Void
}


@objc public protocol AudioPlayingDelegate{
    ///当前播放已完成
    @objc optional func audioPlaying(didFinishPlay:AudioRecord)
    ///播放失败
    @objc optional func audioPlayFaild(failed:AudioRecord)
}


public class AudioRecord: NSObject, AVAudioRecorderDelegate{
    
    deinit{
        destruction()
    }
    
    // 录音器
    private var recorder:AVAudioRecorder?
    // 创建
    private func createRecorde() -> AVAudioRecorder?{
//        //初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
//        //设置录音类型
        try! session.setCategory(AVAudioSession.Category.playAndRecord)
//        //设置支持后台
        try! session.setActive(true)
        //初始化字典并添加设置参数
        let recorderSeetingsDic:[String : Any]? = //录音器设置参数数组
        [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleIMA4),
            AVNumberOfChannelsKey: 2, //录音的声道数，立体声为双声道
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVSampleRateKey : 44100.0, //录音器每秒采集的录音样本数
            AVLinearPCMBitDepthKey : 16,
        ]
        
        let recorder = try? AVAudioRecorder(url: URL(string: cafPath)!, settings: recorderSeetingsDic!)
        recorder?.delegate = self
        return recorder
    }

    private var player:AVAudioPlayer? //播放器
    private var playerVolume:Float = 0.8 ///播放器的播放音量
    
    private var volumeTimer:Timer? //定时器线程，循环监测录音的音量大小
    private var cafPath:String = { //录音存储路径
        //获取Document目录
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask, true)[0]
        //组合录音文件路径
        return docDir + "/vieoRecord.caf"
    }()

    public weak var recordDelegate:AudioRecordDelegate? ///录制代理
    public weak var playDelegate:AudioPlayingDelegate? ///播放代理
    
    public var minTime:Double = 1.0  ///录制最短时长
    public var maxTime:Double = 3600  ///录制最长时长
    
    /// 是否正在播放  控制播放的唯一性
    public var isPlaying:Bool = false
    
    
    /// 外部查看是否授权语音录制，并提示授权信息
    public static func checkAudioAuth() -> Bool{
        var bCanRecord = true
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch audioAuthStatus {
        case .notDetermined: // 未询问用户是否授
            bCanRecord = false
//            if #available(iOS 17.0, *) {
//                AVAudioApplication.requestRecordPermission { allowed in
//                    if (allowed) {
//                        bCanRecord = true;
//                    } else {
//                        bCanRecord = false
//                    }
//                }
//            } else {
                // Fallback on earlier versions
                let audioSession = AVAudioSession.sharedInstance()
                audioSession.requestRecordPermission { allowed in
                    if (allowed) {
                        bCanRecord = true;
                    } else {
                        bCanRecord = false
                    }
                }
//            }
        case .restricted, .denied: ///未授权
            bCanRecord = false
        default:
            bCanRecord = true
        }
        return bCanRecord
    }

    
    ///开始录音
    public func startRecording(){
        //初始化录音器
        
        guard canRecord() else {
            debugPrint("==SWToolKit==" + #file,"不允许或者不能录制")
            recordDelegate?.audioRecord?(audioRecord: self, start: false)
            return
        }
        
        player?.stop()
        /*******录音时停止播放 删除曾经生成的文件*********/
        destructionRecordingFile(path: cafPath)
        
        if recorder == nil {
            /// 创建一个新的
            recorder = createRecorde()
            
            if recorder != nil {
                //开启仪表计数功能
                recorder!.isMeteringEnabled = true
                //准备录音
                recorder!.prepareToRecord()
                //开始录音
                recorder!.record()
                //启动定时器，定时更新录音音量
                volumeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(levelTimer), userInfo: nil, repeats: true)
                
                recordDelegate?.audioRecord?(audioRecord: self, start: true)
            }
        }
    }
    
    ///结束录音
    public func stopRecording(){
        if let recorder1 = recorder, recorder1.isRecording {
            /*****暂停获取录音时间******/
            recorder1.pause()
            /*****暂停计时器******/
            volumeTimer?.invalidate()
            volumeTimer = nil
            
//            try? AVAudioSession.sharedInstance().setCategory(.playback)
            
            if recorder1.currentTime >= minTime {
                convertM4a(totalTime: recorder1.currentTime)
            }else{
                self.recordDelegate?.audioRecord?(audioRecord: self, failType: .timeShort)
            }
            recorder1.stop()
            recorder = nil
        }
        
    }
    
    ///销毁录制的音频文件
    public func destruction() {
        destructionRecordingFile(path: cafPath)
        recorder?.deleteRecording()
        recorder = nil
    }

}


/// 私有
extension AudioRecord {
    
    
    
    ///判断是否可以录制
    private func canRecord() -> Bool{
        let auth = AudioRecord.checkAudioAuth()
        if !auth{
            let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            self.recordDelegate?.audioRecord?(audioRecord: self, audioAuthState: audioAuthStatus)
        }
        return auth
    }
    
    //定时检测录音音量
    @objc private func levelTimer(){
        recorder!.updateMeters() // 刷新音量数据
        //        let averageV:Float = recorder!.averagePower(forChannel: 0) //获取音量的平均值
        let maxV:Float = recorder!.peakPower(forChannel: 0) //获取音量最大值
        let lowPassResult:Double = pow(Double(10), Double(0.05*maxV)) ///录音的音量
        ///回到当前音量
        let recordTime = self.recorder?.currentTime ?? 0
        self.recordDelegate?.audioRecord?(audioRecord: self, recordingTime: recordTime, volum: lowPassResult)
        if recordTime >= maxTime && recordTime >= minTime{
            stopRecording()
        }
    }
    
    

    private func convetCafToM4a(cafUrlStr:String, complete:@escaping((_ error:Error?, _ newFilePath:URL?)->Void)) {
        
        let composition = AVMutableComposition()
        
        let audioLocalUrls = [cafUrlStr]
        
        for i in 0 ..< audioLocalUrls.count {
            
            let compositionAudioTrack : AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
            let asset = AVURLAsset(url: URL.init(fileURLWithPath: audioLocalUrls[i]))
            let tracks = asset.tracks(withMediaType: .audio)
            if tracks.count > 0{
                let track = tracks[0]
                var timeRange:CMTimeRange
                timeRange = CMTimeRange(start: CMTime(value: 0, timescale: 600), duration: track.timeRange.duration)
                
                try! compositionAudioTrack?.insertTimeRange(timeRange, of: track, at: composition.duration)
            }
        }
        
        
        let fileName = "/"+getNowTimeTimestamp()+".m4a"
        //获取Document目录
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0]
        //组合录音文件路径
        let newFilePath = docDir + fileName
        ///NSUrl
        let mergeAudioURL = NSURL.fileURL(withPath: newFilePath) as URL
        
        let assetExport = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.outputFileType = .m4a
        assetExport?.outputURL = mergeAudioURL
        
        assetExport?.exportAsynchronously(completionHandler: {
            switch assetExport!.status
            {
            case .failed:
                debugPrint("==SWToolKit==" + "failed \(String(describing: assetExport?.error))")
            case .cancelled:
                debugPrint("==SWToolKit==" + "cancelled\(String(describing: assetExport?.error))")
            case .unknown:
                debugPrint("==SWToolKit==" + "unknown\(String(describing: assetExport?.error))")
            case .waiting:
                debugPrint("==SWToolKit==" + "waiting\(String(describing: assetExport?.error))")
            case .exporting:
                debugPrint("==SWToolKit==" + "exporting\(String(describing: assetExport?.error))")
            default:
                debugPrint("==SWToolKit==" + "success\(String(describing: assetExport?.error))")
                ///删除文件
                for i in 0..<audioLocalUrls.count{
                    self.destructionRecordingFile(path: audioLocalUrls[i])
                }
            }
            complete(assetExport?.error, mergeAudioURL)
        })
    }

    
    //caf转换成mp3
    private func convertMp3(cafUrlStr:String, complete:@escaping((_ error:Error?, _ newFilePath:String?)->Void)){
        
    }
    
    /// 获得当前时间戳
    private func getNowTimeTimestamp() -> String{
        let dat = NSDate.init(timeIntervalSinceNow: 0)
        let a = dat.timeIntervalSince1970
        return String(a)
    }
    
    
    //MARK: AVAudioRecorderDelegate
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    
    
    ///删除当前路径的文件
    private func destructionRecordingFile(path:String){
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) == true{
            do{
                try fileManager.removeItem(atPath: path)
            }catch{
                debugPrint("==SWToolKit==" + #file,error)
            }
            
        }
    }
    
    //MARK:  音频转换
    private func convertM4a(totalTime:TimeInterval) -> Void {
        convetCafToM4a(cafUrlStr: cafPath) {[weak self] error, newFilePath in
            if let fileP = newFilePath {
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        self?.recordDelegate?.audioRecord?(audioRecord: strongSelf, resultRecordPath: fileP, recordTime: totalTime)
                    }
                }
            }
        }
    }
    
}


