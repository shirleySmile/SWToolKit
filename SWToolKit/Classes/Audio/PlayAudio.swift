//
//  PlayAudio.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/9.
//

import Foundation
import AVFoundation


public class PlayAudio {
    
    public static let share = PlayAudio()
    
    ///不冲突的音效
    
    private var timeObserver:Any?
    
    /*********************背景空白音乐******************/
    ///播放空白音乐
    ///空白音乐播放
    private var blankPlayer:AVAudioPlayer?
    fileprivate let audioSession = AVAudioSession.sharedInstance()
    public func playBackgroundBlankMusic(name:String, loop:Int){
        /// 原实现用 isInputAvailable 作为播放前提：该值仅在会话类别允许录音（.playAndRecord/.record）且硬件有输入时为 true，
        /// 默认类别（.soloAmbient）及 .playback 下恒为 false，导致音效在未开启录音会话的 App 里永远不播放，已移除该判断
        blankPlayer?.stop()
        blankPlayer = nil
        
        guard let soundPath = Bundle.main.path(forResource: name, ofType: "mp3") else {
            return
        }
        
        setupAudioSession()
        
        do {
            //初始化播放器对象
            blankPlayer = try AVAudioPlayer.init(contentsOf:URL(fileURLWithPath: soundPath))
            //设置声音的大小
            blankPlayer?.volume = 0 //范围为（0到1）
            //设置循环次数，如果为负数，就是无限循环
            blankPlayer?.numberOfLoops = loop
            //设置播放进度
            blankPlayer?.currentTime = 0
            //准备播放
            blankPlayer?.prepareToPlay()
            blankPlayer?.play()
            
        } catch {
            debugPrint("==SWToolKit==" + "空白音乐播放失败:", error)
        }
    }
    ///停止播放空白音乐
    public func stopBackgroundBlankMusic(){
        blankPlayer?.stop()
        blankPlayer = nil
        do {
            try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch let error {
            debugPrint("==SWToolKit==" + "\(type(of:self)):\(error)")
        }
    }
    
    private func setupAudioSession() {
        do {
            try self.audioSession.setCategory(.playback, options:.mixWithOthers)
            try self.audioSession.setActive(true)
        } catch let error {
            debugPrint("==SWToolKit==" + "\(type(of:self)):\(error)")
        }
    }
    
    /*********************Message******************/
    
    ///一次播放消息声音
    ///消息播放
    private var audioPlayer:AVAudioPlayer?
    public func play(name:String, type:String = "wav", loop:Int = 0){
        /// 原实现用 isInputAvailable 作为播放前提（见 playBackgroundBlankMusic 注释），已移除
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0 //将播放的进度设置为初始状态
        
        guard let soundPath = Bundle.main.path(forResource: name, ofType: type) else {
            return
        }
        
        do {
            //初始化播放器对象
            audioPlayer = try AVAudioPlayer.init(contentsOf:URL(fileURLWithPath: soundPath))
            //设置声音的大小
            audioPlayer?.volume = 0.8 //范围为（0到1）
            //设置循环次数，如果为负数，就是无限循环
            audioPlayer?.numberOfLoops = max(loop, -1)
            //设置播放进度
            audioPlayer?.currentTime = 0
            //准备播放
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
        } catch {
            debugPrint("==SWToolKit==" + "音效播放失败:", error)
        }
    }
    
    public func stopPlayMsgAudio(){
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    ///普通短振动 （类似3D Touch的peek反馈）
    public static func short1Shark(){
        AudioServicesPlaySystemSound(1519)
    }
    /// 点击振动 （类似3D Touch的pop反馈）
    public static func short2Shark(){
        AudioServicesPlaySystemSound(1520)
    }
    
    /// 一般振动
    public static func oneShark(){
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    /// 点击的开关
    public static func touchShark(){
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    /// 连续三次短振
    public static func threeShark(){
        AudioServicesPlaySystemSound(1521)
    }
    
    
    /********************播放网络音乐******************/
    ///网络音效播放
    private var netAudioPlayer:AVPlayer?
    /// 标记本轮播放是否已触发过结尾处理（周期回调每秒都会触发，防止结尾逻辑重复执行）
    private var netAudioEndTriggered = false
    public func playNetAudio(filePath:String, loop: Int, complete:(()->Void)?) {
        stopPlayNetAudio()
        
        guard let url = URL(string: filePath) else {
            debugPrint("==SWToolKit==" + "音频地址无效:", filePath)
            return
        }
        netAudioEndTriggered = false
        let item = AVPlayerItem(url: url)
        netAudioPlayer = AVPlayer.init(playerItem: item)
        netAudioPlayer?.volume = 0.8
        
        timeObserver = netAudioPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: .main, using: { [weak self] time in
            let duration = self?.netAudioPlayer?.currentItem?.duration ?? .invalid
            let totalSeconds = CMTimeGetSeconds(duration)
            let currentSeconds = CMTimeGetSeconds(time)
            guard totalSeconds.isFinite, totalSeconds > 0 else { return }
            let rate = currentSeconds/totalSeconds
            
            if rate > 0.99 {
                /// 周期回调每秒触发一次，结尾处会连续命中，只处理第一次
                guard !(self?.netAudioEndTriggered ?? false) else { return }
                self?.netAudioEndTriggered = true
                switch loop {
                case 1,0: ///最后一次播放
                    complete?()
                case -1: ///循环播放
                    DispatchQueue.global().asyncAfter(deadline: .now()+0.5) {
                        self?.playNetAudio(filePath: filePath, loop: loop, complete:complete)
                    }
                default:
                    let newloop = loop-1
                    DispatchQueue.global().asyncAfter(deadline: .now()+0.5) {
                        self?.playNetAudio(filePath: filePath, loop: newloop, complete:complete)
                    }
                }
            }
        })
        netAudioPlayer?.play()
        
    }
    
    public func stopPlayNetAudio(){
        netAudioPlayer?.pause()
        if timeObserver != nil {
            netAudioPlayer?.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
        netAudioPlayer = nil;
    }
    
    
    
    //系统声音播放mp3音效
    private var soundFileObject: SystemSoundID = 0
    public func playSystemSound(name:String, type:String){
        guard let soundPath = Bundle.main.path(forResource: name, ofType:type) else {
            debugPrint("==SWToolKit==" + "音效文件不存在:", name, type)
            return
        }
        soundFileObject = 0
        AudioServicesCreateSystemSoundID(URL(fileURLWithPath: soundPath) as CFURL, &soundFileObject)
        AudioServicesPlaySystemSound(soundFileObject)
    }
    
}
