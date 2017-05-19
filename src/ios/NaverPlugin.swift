import UIKit

@objc(NaverPlugin) class NaverPlugin: CDVPlugin {
    var callbackScheme: String?;

    override func pluginInitialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(NaverPlugin.applicationDidBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        AppDelegate.classInit
    }

    func applicationDidBecomeActive(application: UIApplication) {
        let clientId = Bundle.main.object(forInfoDictionaryKey: CLIENT_ID)
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: CLIENT_SECRET)
        let clientName = Bundle.main.object(forInfoDictionaryKey: CLIENT_NAME)
        self.callbackScheme = Bundle.main.object(forInfoDictionaryKey: CALLBACK_SCHEME) as? String

        let naverLogin:NaverThirdPartyLoginConnection = NaverThirdPartyLoginConnection.getSharedInstance()

        naverLogin.isInAppOauthEnable = true
        naverLogin.serviceUrlScheme = self.callbackScheme
        naverLogin.consumerKey = clientId as? String
        naverLogin.consumerSecret = clientSecret as? String
        naverLogin.appName = clientName as? String
    }

    @objc(login:) func login(command: CDVInvokedUrlCommand) {

    }
}