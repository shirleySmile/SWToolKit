//
//  VoipRing.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/10.
//

import Foundation
import UIKit
import PushKit
import AudioToolbox

@objc protocol VoipRingDelegate {
    
    func voipServerToken(data:Data) -> Void;
    
}

class VoipRing : NSObject, PKPushRegistryDelegate {
    
    var timer: DispatchSourceTimer?
    var bgTask: UIBackgroundTaskIdentifier?
    weak var delegate: VoipRingDelegate?
    weak var notificationDelegate:PushManager?
    
    
    ///注册推送key
    func registerPushKit() {
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipRegistry.delegate = self
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    ///开始
    func onStartRing(param:[AnyHashable:Any]) {
        switch (UIApplication.shared.applicationState) {
        case .active:
            ///在前台不接
            return
        default:
            break;
        }
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "PKPushIncomingCallReportedNotification"), object: nil)
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "MyTask", expirationHandler: { [weak self] in
            guard let self = self else { return }
            self.onCancelRing()
            if let taskID = self.bgTask, taskID != .invalid {
                UIApplication.shared.endBackgroundTask(taskID)
            }
            self.bgTask = .invalid
        })
        
        ///添加通知
        addNotification()
        
        let apnDic:[String:Any]? = param["aps"] as? Dictionary
        let alertDic:[String:Any]? = apnDic?["alert"] as? Dictionary
        
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        
        let content = UNMutableNotificationContent()
        content.title = alertDic?["title"] as? String ?? ""
        content.body = alertDic?["subTitle"] as? String ?? ""
        
        let customSound = UNNotificationSound.init(named: UNNotificationSoundName.init(rawValue: "call.wav"))
        content.sound = customSound
        content.userInfo = param
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "Voip_Push", content: content, trigger: trigger)
        
        center.add(request) { error in
        }
    }
    
    
    ///结束
    func onCancelRing(){
        otherCancelRing()
    }
    
    
    //MARK: private
    
    private func addNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(otherCancelRing), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(otherCancelRing), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(otherCancelRing), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(otherCancelRing), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    private func removeNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func otherCancelRing(){
        stopPlaySystemSound()
        removeNotification()
        if bgTask != nil {
            UIApplication.shared.endBackgroundTask(bgTask!)
        }
    }
    
    
    
    //MARK: 系统铃声
    private func startPlaySystemSound(){
        if timer == nil {
            // 创建一个 timer 类型定时器 （ DISPATCH_SOURCE_TYPE_TIMER）
            timer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue.global())
            //设置定时器的各种属性（何时开始，间隔多久执行）
            // GCD 的时间参数一般为纳秒 （1 秒 = 10 的 9 次方 纳秒）
            // 指定定时器开始的时间和间隔的时间
            timer?.schedule(deadline: .now(), repeating: .seconds(1))
            
            ///循环次数
            var param:Int = 50
            timer?.setEventHandler(handler: { [weak self] in
                param = param-1
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                if param == 0 {
                    self?.onCancelRing()
                }
            })
            
            timer?.resume()
        }
    }
    
    private func stopPlaySystemSound(){
        if let timer = timer {
            /// 已 resume 的 DispatchSourceTimer 被系统强持有，必须 cancel 才会停止触发
            timer.cancel()
        }
        timer = nil
    }
    
    
    
    //MARK: PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if pushCredentials.token.count == 0 {
            debugPrint("==SWToolKit==" + "ApplePush推送voip token NULL");
            return
        }
        delegate?.voipServerToken(data: pushCredentials.token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        guard type == .voIP else{
            return
        }
        
        debugPrint("==SWToolKit==" + "ApplePush推送收到---voip推送 ----实现客户端逻辑~~~\(payload.dictionaryPayload)~~~\(type)")
        
        ///通话
        if let extraMap:String = payload.dictionaryPayload["extraMap"] as? String,
           let data:Data = extraMap.data(using: .utf8),
           let param = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? Dictionary<String, Any>,
           let pushType = param["pushType"] as? Int {
            if pushType == 10 {
                if timer == nil {
                    onStartRing(param: payload.dictionaryPayload)
                }
            }
            
            if pushType == 11 {
                onCancelRing()
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
//        onCancelRing()
    }
    
    
//    //MARK: ///调试用
//    private func test(show:String, pointY:CGFloat){
//        var param = "sdssfsfdsdfsdfdsf";
//        switch (UIApplication.shared.applicationState) {
//        case .active:
//            param = "在前台活跃"
//        case .inactive:
//            param = "在不活跃"
//        case .background:
//            param = "在后台"
//        default:
//            break;
//        }
//
//        let lab = UILabel.init(frame: CGRect(x: 0, y: pointY, width: 400, height: 50))
//        lab.text = param+"-"+show+":"+Date().stringFmt( " HH:mm:ss")
//        lab.textColor = UIColor.red;
//        lab.font = UIFont.systemFont(ofSize: 34)
//        lab.textAlignment = .center;
//        kHighWindow?.addSubview(lab)
//    }
//    
}
