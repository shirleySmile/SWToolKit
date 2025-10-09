//
//  PushManager.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/9.
//

import Foundation
import UIKit


/// 推送配置
public protocol NotificationConfig {
    ///注册推送信息
    static func registeUserNotificationInfo(pushToken:String, voipToken:String)
    ///接收后的推送消息
    static func receiveNotificationInfo(active:Bool,info:[String:Any])
}


class PushInfoHandle:NSObject{
    ///数据<pushID, date>
    lazy var param:[String : Any] = Dictionary()
    private let pushUserDef = UserDefaults.init(suiteName: "PushInfoHandleDef")
    override init(){
        super.init()
        let tempDic:[String:Any]? = pushUserDef?.object(forKey: "PushInfoHandle") as? Dictionary
        if tempDic != nil {
            param.merge(other: tempDic!)
        }
    }
    
    func savePushId(pushId:String) {
        if pushId.count == 0 {
            return
        }
        ///当天时间
        let dataFmt = DateFormatter()
        dataFmt.dateFormat = "yyyy-MM-dd";
        let currentData:String = dataFmt.string(from: Date())
        param[pushId] = currentData
        pushUserDef?.set(param, forKey: "PushInfoHandle")
        pushUserDef?.synchronize()
        
        ///删除旧数据
        let tempDic:[String:Any] = param
        for (key,value) in tempDic {
            ///如果保存的数据日期不等于当天 && 当前的推送ID也不等于保存的ID ---》删除该数据
            if ((value as!String) != currentData) && (pushId != key) {
                param.removeValue(forKey: key)
            }
        }
    }
    
    func existsPushId(pushId:String) -> Bool {
        var exists = false
        if pushId.count > 0{
            for (key, _) in param {
                if pushId == key {
                    exists = true
                    break
                }
            }
        }
        return exists
    }
    
}


///推送数据处理

public class PushManager: NSObject, UNUserNotificationCenterDelegate,VoipRingDelegate{
    
    private var launchedByNotification:Bool = false
    
    private var pushTokenStr: String = "" ///苹果推送注册Token字符串
    private var voipTokenStr: String = "" ///苹果Voip注册token字符串
    private let pushHandle:PushInfoHandle = PushInfoHandle() ///收到推送消息处理
    private var voipRing:VoipRing?
    private var notificationConfig:NotificationConfig.Type! /// 推送配置
    
    public static let share = PushManager()
    private override init() {
        super.init()
    }
    
    
    ///app启动就注册
    public func registerNotification(application:UIApplication, launchOptions:[UIApplication.LaunchOptionsKey: Any]?, config:NotificationConfig.Type) {
        
        notificationConfig = config
        ///是否有远程推送消息
        let remoteNotification = launchOptions?[.remoteNotification]
        launchedByNotification = (remoteNotification == nil) ? false : true
        
        //        self.registerVOIP()
        
        //iOS 10 later   注册推送
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.getNotificationSettings { (setting) in
                if setting.authorizationStatus == .notDetermined {
                    center.requestAuthorization(options: [.badge,.sound,.alert]) { (result, error) in
                        if(result){
                            if !(error != nil){
                                // 注册成功
                                DispatchQueue.main.async {
                                    application.registerForRemoteNotifications()
                                }
                            }
                        } else{
                            //用户不允许推送
                        }
                    }
                } else if (setting.authorizationStatus == .denied){
                    // 申请用户权限被拒
                } else if (setting.authorizationStatus == .authorized){
                    // 用户已授权（再次获取dt）
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    // 未知错误
                }
            }
        }
        
        ///10版本以前的系统不管
        application.registerForRemoteNotifications()
    }
    
    ///注册koken
    public func registerDeviceToken(deviceToken:Data){
        pushTokenStr = setUserNotificationRegisterId(deviceToken: deviceToken)
        registerUserIdentifier()
    }
    
    ///用户登录后重新注册设备
    public func userLoginRegisterToken(){
        registerUserIdentifier()
    }
    
    ///处理用户的数据
    private func handleUserInfo(userInfo:[AnyHashable : Any]){
        MessageInfo.print("ApplePush推送系统，收到通知:\(userInfo)");
        if let extraMap = (userInfo["extraMap"] as? String){
            if launchedByNotification {
                MessageInfo.print("ApplePush推送程序关闭(杀死)状态点击推送消息打开应用")
                DispatchQueue.main.asyncAfter(deadline: .now()+5.0) {
                    self.pushDataBlock(extraMap: extraMap, active: false)
                }
            }else{
                if UIApplication.shared.applicationState == .active {
                    MessageInfo.print("ApplePush推送程序前台运行");
                    self.pushDataBlock(extraMap: extraMap, active: true)
                } else {
                    MessageInfo.print("ApplePush推送程序挂起但未被杀死");
                    self.pushDataBlock(extraMap: extraMap, active: false)
                }
            }
        }
    }
    
    ///向服务器注册本机的信息
    private func registerUserIdentifier() {
        if pushTokenStr.count > 0 {
            notificationConfig.registeUserNotificationInfo(pushToken: pushTokenStr, voipToken: voipTokenStr)
        }
    }
    
    ///处理推送的数据
    private func pushDataBlock(extraMap:String, active:Bool){
        let data = extraMap.data(using: .utf8)
        let param:[String:Any]? = (try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers)) as? [String:Any]
        
        if let pushId = param?["pushId"] as? String, pushId.count > 0 && pushHandle.existsPushId(pushId: pushId) == false {
            pushHandle.savePushId(pushId: pushId)
            notificationConfig.receiveNotificationInfo(active: active, info: param!)
        }
    }
    
    ///将从服务器获取的token转成字符串
    private func setUserNotificationRegisterId(deviceToken:Data) -> String {
        var deviceTokenString:String = ""
        let bytes = [UInt8](deviceToken)
        for item in bytes {
            deviceTokenString += String(format: "%02x", item&0x000000FF)
        }
        print(deviceTokenString)
        return deviceTokenString
    }
    
    
    //MARK: UNUserNotificationCenterDelegate
    //    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    //
    //    }
    
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let content = response.notification.request.content;
        let userInfo = content.userInfo;
        if ((response.notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self)) != nil) {
            MessageInfo.print("ApplePush推送iOS10 收到远程通知")
        }else{
            MessageInfo.print("ApplePush推送iOS10 收到本地通知")
        }
        
        voipRing?.onCancelRing()
        
        handleUserInfo(userInfo: userInfo)
        // 此处必须要执行下行代码，不然会报错
        completionHandler();
        
    }
    
    //    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
    //    }
    
    
    //MARK: VoipRingDelegate
    func voipServerToken(data: Data) {
        voipTokenStr = setUserNotificationRegisterId(deviceToken: data)
        MessageInfo.print("ApplePush推送拿到token~~~\(data)~~~~\n~~~-\(String(describing: voipTokenStr))")
        registerUserIdentifier()
    }
    
    private func registerVOIP(){
        voipRing = VoipRing()
        voipRing?.delegate = self;
        voipRing?.notificationDelegate = self;
        voipRing?.registerPushKit()
    }
    
}


