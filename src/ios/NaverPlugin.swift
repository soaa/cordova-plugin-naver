    import UIKit

    @objc(NaverPlugin) class NaverPlugin: CDVPlugin, NaverThirdPartyLoginConnectionDelegate {

        var lastCommand: CDVInvokedUrlCommand?

        override init() {

        }

        override func pluginInitialize() {
            NotificationCenter.default.addObserver(self, selector: #selector(NaverPlugin.applicationDidBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)

            AppDelegate.naverPluginClassInit
        }

        func applicationDidBecomeActive(application: UIApplication) {
            let bundle = Bundle.main
            let clientId = bundle.object(forInfoDictionaryKey: CLIENT_ID) as? String
            let clientSecret = Bundle.main.object(forInfoDictionaryKey: CLIENT_SECRET) as? String
            let clientName = Bundle.main.object(forInfoDictionaryKey: CLIENT_NAME) as? String
            let callbackScheme = Bundle.main.object(forInfoDictionaryKey: CALLBACK_SCHEME) as? String

            let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()

            naverLogin.isNaverAppOauthEnable = true
            naverLogin.isInAppOauthEnable = true
            naverLogin.serviceUrlScheme = callbackScheme
            naverLogin.consumerKey = clientId
            naverLogin.consumerSecret = clientSecret
            naverLogin.appName = clientName
            naverLogin.delegate = self


        }

        @objc(login:) func login(command: CDVInvokedUrlCommand) {
            let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()
            // TODO: ios 개발환경에 익숙하지 않으나 multi-thread 환경에 취약해보이므로...
            objc_sync_enter(self)

            self.lastCommand = command
            naverLogin.requestThirdPartyLogin()
        }
        
        @objc(logout:) func logout(command: CDVInvokedUrlCommand) {
            let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()

            naverLogin.resetToken()
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
            
            /*
            objc_sync_enter(self)
            
            self.lastCommand = command
            naverLogin.requestDeleteToken()
            */
        }

        func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection, didFailWithError error: Error) {
            NSLog("did fail with error: %s", error.localizedDescription)
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription), callbackId: self.lastCommand?.callbackId)

            objc_sync_exit(self)
        }

        func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFinishAuthorizationWithResult recieveType: THIRDPARTYLOGIN_RECEIVE_TYPE) {
            if (recieveType != SUCCESS) {
                NSLog("did fail with error: %d", recieveType.rawValue)
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR), callbackId: self.lastCommand?.callbackId)
                objc_sync_exit(self)
            }
        }

        func oauth20ConnectionDidFinishDeleteToken() {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: self.lastCommand?.callbackId)

            objc_sync_exit(self)
        }

        func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
            NSLog("oauth20ConnectionDidFinishRequestACTokenWithRefreshToken called")

            sendResponseWithToken()
        }

        func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
            NSLog("oauth20ConnectionDidFinishRequestACTokenWithAuthCode called")
            sendResponseWithToken()
        }

        func sendResponseWithToken() {

            let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()

            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
                "access_token" : naverLogin.accessToken,
                "refresh_token" : naverLogin.refreshToken,
                "expires_at" : Int(NSInteger(naverLogin.accessTokenExpireDate.timeIntervalSince1970) / 1000)
                ]), callbackId: self.lastCommand?.callbackId)

            objc_sync_exit(self)
        }

        func oauth20ConnectionDidOpenInAppBrowser(forOAuth request: URLRequest!) {
            let view:UIViewController = NLoginThirdPartyOAuth20InAppBrowserViewController(request: request)

            self.viewController.present(view, animated: true, completion: nil)

        }

    }


    //MARK: extension NaverPlugin
    extension AppDelegate {

        static let naverPluginClassInit : () = {
            let swizzle = { (cls: AnyClass, originalSelector: Selector, swizzledSelector: Selector) in
                let originalMethod = class_getInstanceMethod(cls, originalSelector)
                let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector)

                let didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

                if didAddMethod {
                    class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
                } else {
                    method_exchangeImplementations(originalMethod, swizzledMethod);
                }
            }
            swizzle(AppDelegate.self, #selector(UIApplicationDelegate.application(_:open:sourceApplication:annotation:)), #selector(AppDelegate.nnSwizzledApplication(_:open:sourceApplication:annotation:)))
            
            if #available(iOS 9.0, *) {
                swizzle(AppDelegate.self, #selector(UIApplicationDelegate.application(_:open:options:)), #selector(AppDelegate.nnSwizzledApplication_options(_:open:options:)))
            }
        }()

        open func nnSwizzledApplication(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) {
            self.handleNaverURL(url)
            self.nnSwizzledApplication(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        }
        
        open func nnSwizzledApplication_options(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) {
            let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()
            if (url.scheme?.caseInsensitiveCompare(naverLogin.serviceUrlScheme) == .orderedSame) {
                naverLogin.application(application, open: url, options: options)
            }
            self.nnSwizzledApplication_options(application, open: url, options: options)
        }
        
        
        func handleNaverURL(_ url: URL) -> Bool {
            let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()
            if (url.scheme == naverLogin.serviceUrlScheme) {
                naverLogin.receiveAccessToken(url)
                return true
            }

            return false
        }
    }

