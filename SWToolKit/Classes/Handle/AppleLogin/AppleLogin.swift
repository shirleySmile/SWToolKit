//
//  AppleLogin.swift
//  SWToolKit
//
//  Created by shirley on 2022/4/8.
//

import Foundation
import AuthenticationServices

public struct AppleUser{
    public var userId:String?
    public var userName:String?
    public var authCode:String?
    public var token:String?
}


public class AppleLogin: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding{
    
    public enum AppleLoginResultType {
        case success
        case fail
        case nonSupport
        case userCancel
    }
    
    public typealias resultClosure = (AppleLoginResultType, AppleUser?)->()
    var userInfoBlock:resultClosure?
    
    
    public func authInfo(callback: @escaping resultClosure) {
        if #available(iOS 13.0, *){
            userInfoBlock = callback
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let authAppleIDRequest = appleIDProvider.createRequest()
            
            var array:[ASAuthorizationRequest] = []
            array.append(authAppleIDRequest);
            
            
            let authorizationController = ASAuthorizationController.init(authorizationRequests: array)
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self;
            authorizationController.performRequests()
            
        }else{
            callback(.nonSupport, nil)
            debugPrint("==SWToolKit==" + #file,"系统不支持Apple登录")
        }
    }
    
    
    //MARK: ASAuthorizationControllerPresentationContextProviding
    @available(iOS 13.0, *)
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.last!
    }
    
    
    //MARK: ASAuthorizationControllerDelegate
    // 授权失败
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        if let e = error as? ASAuthorizationError {
            var errorMsg:String = ""
            var errorType:AppleLoginResultType = .fail
            switch e.code {
            case .canceled:
                errorType = .userCancel
                errorMsg = "用户取消了授权请求";
            case .failed:
                errorMsg = "授权请求失败";
            case .invalidResponse:
                errorMsg = "授权请求响应无效";
            case .notHandled:
                errorMsg = "未能处理授权请求";
            case .unknown:
                errorMsg = "授权请求失败未知原因";
            case .notInteractive:
                errorMsg = "没有交互"
            case .matchedExcludedCredential:
                errorMsg = "尝试使用了一个已被排除的凭证"
            case .credentialImport:
                errorMsg = "证书导入"
            case .credentialExport:
                errorMsg = "证书导出"
            case .preferSignInWithApple:
                errorMsg = "偏好用苹果登陆"
            case .deviceNotConfiguredForPasskeyCreation:
                errorMsg = "设备未配置密码键"
            @unknown default:
                errorMsg = "默认";
            }
            debugPrint("==SWToolKit==" + #file,errorMsg)
            DispatchQueue.main.async {
                if self.userInfoBlock != nil {
                    self.userInfoBlock!(errorType, nil)
                    self.userInfoBlock = nil
                }
            }
        }
    }
    
    
    /// Apple登录授权成功
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        var aUser:AppleUser?
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            /**
             - 首次注册 能够那去到的参数分别是：
             1. user
             2.state
             3.authorizedScopes
             4.authorizationCode
             5.identityToken
             6.email
             7.fullName
             8.realUserStatus
             */
            // 苹果用户唯一标识符，该值在同一个开发者账号下的所有 App 下是一样的，开发者可以用该唯一标识符与自己后台系统的账号体系绑定起来
            let userIdentifier = appleIDCredential.user
            // 苹果用户信息 如果授权过，可能无法再次获取该信息
            let fullName = appleIDCredential.fullName
            //            let email = appleIDCredential.email
            // 服务器验证需要使用的参数
            let code = String(data: appleIDCredential.authorizationCode!, encoding: .utf8)
            let token = String(data: appleIDCredential.identityToken!, encoding: .utf8)
            // 用于判断当前登录的苹果账号是否是一个真实用户，取值有：unsupported、unknown、likelyReal
            //            let realUserStatus = appleIDCredential.realUserStatus;
            
            aUser = AppleUser(userId: userIdentifier, userName: fullName?.nickname, authCode: code, token: token);
            
        case let passwordCredential as ASPasswordCredential:
            
            // 用户登录使用现有的密码凭证
            let username = passwordCredential.user
            //            let password = passwordCredential.password
            aUser = AppleUser(userId: username, userName:"", authCode:"" , token: "");
            
        default:
            break
        }
        
        DispatchQueue.main.async {
            if let appleUser = aUser {
                self.userInfoBlock?(.success, appleUser)
            }else{
                self.userInfoBlock?(.fail, nil)
            }
            self.userInfoBlock = nil
        }
        
    }
}
