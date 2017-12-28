//
//  IRecLibrary.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/26.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

class Channel: NSObject, Printable {
    var href: String
    var chnumber: String?
    var chlogo: String?
    var chlogo_alt: String
    var chname: String
    var channelsel: String?

    init(name: String, href: String) {
        self.chname=name
        self.href=href
        self.channelsel=name.substringFromIndex(advance(name.rangeOfString("=")!.startIndex,1))
        self.chlogo_alt="";
    }
    
    init(element: HTMLElement) {
        let a: HTMLElement=element.nodesMatchingSelector("a")![0] as! HTMLElement
        self.href=a.attributes["href"] as! String
        self.chlogo_alt=""
        self.chname=""
        self.channelsel=href.substringFromIndex(advance(href.rangeOfString("=")!.startIndex,1))
        
        for span: HTMLElement in a.childElementNodes as! Array<HTMLElement> {
            let cssClass=span.attributes["class"] as! String
            switch cssClass {
            case "chnumber":
                self.chnumber=span.textContent!
            case "chlogo":
                let img: HTMLElement=span.nodesMatchingSelector("img")![0] as! HTMLElement
                self.chlogo=img.attributes["src"] as? String
                self.chlogo_alt=img.attributes["alt"]! as! String
            case "chname":
                self.chname=span.textContent
            default: ()
            }
        }
        
    }
    
    override var description: String {
        return "NW=\(chlogo_alt) CH=\(chnumber!) CN=\(chname)"
    }
    
    func toString() -> String {
        return self.description
    }
}

class Device: NSObject, Printable {
    var href: String
    var name: String
    
    init(name: String, href: String) {
        self.href=href
        self.name=name
    }
    
    init(element: HTMLElement) {
        let a:HTMLElement=element.nodesMatchingSelector("a")![0] as! HTMLElement
        self.href=a.attributes["href"]! as! String
        self.name=a.textContent.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
    }
    
    override var description: String {
        return self.name
    }
    
    func toString() -> String {
        return self.description
    }
}

class Programme: NSObject, Printable, Comparable {
    var name: String?
    var href: String
    var progtime: String
    var progday: String
    var progname: String
    var timestamp: NSTimeInterval = 0
    var duration: Int = 0
    var multi: Bool = false
    static var lastProgramme: Programme?
    static var lastPD: String?
    
    init(element:HTMLElement) {
        let a:HTMLElement=element.nodesMatchingSelector("a")![0] as! HTMLElement
        href=a.attributes["href"]! as! String
        name=a.attributes["name"] as? String
        progtime=""
        progday=""
        progname=""
        
        super.init()
        
        if (Programme.lastPD==nil) {
            // First item and no weekday specified
            let dateFormatter=NSDateFormatter()
            dateFormatter.dateFormat="EEE";
            Programme.lastPD=dateFormatter.stringFromDate(NSDate()).uppercaseString
        }
        
        if name==nil || count(name!) == 0 || name=="jump" {
            name=Programme.lastPD
        } else {
            Programme.lastPD=name!
        }
        
        for span:HTMLElement in a.childElementNodes! as! Array<HTMLElement> {
            let cssClass: String=span.attributes["class"]! as! String
            
            switch cssClass {
            case "progtime": progtime=span.textContent
            case "progday": progday=span.textContent
            case "progname": progname=span.textContent
            default: ()
            }
        }
        
        self.generateTimestamp()
    }
    
    init(jsonObject: Dictionary<String,AnyObject>) {
        href=jsonObject["href"]! as! String
        name=jsonObject["name"] as? String
        progtime=jsonObject["progtime"]! as! String
        progday=jsonObject["progday"]! as! String
        progname=jsonObject["progname"]! as! String
        multi = !((jsonObject["single"] as? Bool) ?? true)

        super.init()
        
        self.generateTimestamp()
        
        duration=jsonObject["duration"]! as! Int
    }
    
    func generateTimestamp() {
        let dateFormatter:NSDateFormatter=NSDateFormatter();
        dateFormatter.dateFormat="y-M-d H:m:s"
        let date:NSDate=dateFormatter.dateFromString(href.substringFromIndex(advance(href.rangeOfString("&datetimesel=")!.startIndex, 13)))!
        let calendar:NSCalendar=NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let addedDate:NSDate=calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitHour, value: 8, toDate: date, options: nil)! // timestamp should be always in UTC
        timestamp=addedDate.timeIntervalSince1970
        
        if (Programme.lastProgramme != nil) {
            Programme.lastProgramme!.duration=Int(timestamp-Programme.lastProgramme!.timestamp);
        }
        duration=0;
        Programme.lastProgramme=nil;
    }
    
    override var description: String {
        return "PD=\(name) PT=\(progtime) TS=\(timestamp) PN=\(progname)"
    }
    
    func toString() -> String {
        return self.description
    }
    
    func toJSONObject() -> Dictionary<String,AnyObject> {
        var jsonObject:Dictionary<String,AnyObject>=[String:AnyObject]()
        
        jsonObject["href"]=href
        jsonObject["name"]=name
        jsonObject["progtime"]=progtime
        jsonObject["progday"]=progday
        jsonObject["progname"]=progname
        jsonObject["single"] = !multi
        
        return jsonObject
    }
    
}

func < (lhs: Programme, rhs: Programme) -> Bool {
    return lhs.timestamp<rhs.timestamp
}

func == (lhs: Programme, rhs: Programme) -> Bool {
    return lhs.timestamp==rhs.timestamp
}

class Href: NSObject, Printable {
    var title: String
    var href: String
    
    init (element: HTMLElement) {
        let li: HTMLElement = element.nodesMatchingSelector("li").first! as! HTMLElement
        self.title = li.textContent
        self.href = (li.childAtIndex(0) as! HTMLElement).attributes["href"] as! String
    }
    
    override var description: String {
        return self.title
    }
    
    func toString() -> String {
        return self.description
    }
}

class IRecLibrary {
    enum ObjectType {
        case CHANNELS
        case PROGRAMMES
        case HREF
        case PROGRAMMEINFO
        case DEVICES
        case EMPTY
        case ERROR
    }
    
    static var instance: IRecLibrary?
    let userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
    let host: String = "http://irec.magictv.com"
    let MOCK: Bool = false
    var loggedIn: Bool = false
    var lang: String = "hk"
    
    private init() {
        IRecLibrary.instance=self
        if self.MOCK { self.loggedIn = true }
    }
    
    class func sharedInstance() -> IRecLibrary {
        if (IRecLibrary.instance==nil) { IRecLibrary.instance = IRecLibrary() }
        return IRecLibrary.instance!
    }
    
    class func clearSession() {
        var cookieStorage: NSHTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        for cookie:NSHTTPCookie in cookieStorage.cookies as! Array<NSHTTPCookie>! {
            cookieStorage.deleteCookie(cookie)
        }
        
        IRecLibrary.instance?.loggedIn=false
        
        IRecLibrary.instance=nil
    }
    
    private func fetchPage(url:String, callback: ((responseData: NSData?, error: NSError?) -> Void)?, referer:String?) -> AnyObject? {
        return self.fetchPage(url, callback: callback, referer: referer, allowRedirect: false)
    }
    
    private func fetchPage(url:String, callback: ((responseData: NSData?, error: NSError?) -> Void)?, referer:String?, allowRedirect:Bool) -> AnyObject? {
        let manager: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager(baseURL: NSURL(string: host))!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: self.host + url.stringByReplacingOccurrencesOfString(" ", withString: "%20"))!)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        if (referer != nil) { request.addValue(referer!, forHTTPHeaderField: "Referer")}
        
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        var error: NSError? = nil
        
        let requestOperation: AFHTTPRequestOperation = manager.HTTPRequestOperationWithRequest(request, success: { (requestOperation: AFHTTPRequestOperation?, data_in_code_entry: AnyObject?) -> Void in
            if callback != nil {
                switch requestOperation!.response.statusCode {
                case 200:
                    callback!(responseData: requestOperation!.responseData, error: nil)
                case 301, 302:
                    var locationObject: AnyObject? = requestOperation!.response.allHeaderFields["Location"]
                    var locationString = (locationObject==nil) ? "" : (locationObject! as! String)
                    let error=NSError(domain: NSPOSIXErrorDomain, code: requestOperation!.response.statusCode, userInfo: ["location" : locationString])
                    
                    callback!(responseData: nil, error: error)
                default:()
                }
            }
            
            dispatch_semaphore_signal(semaphore)
            
            }) { (requestOperation: AFHTTPRequestOperation?, error: NSError?) -> Void in
                if callback != nil {
                    callback!(responseData: nil, error: error)
                }
                dispatch_semaphore_signal(semaphore)
            }
        
        requestOperation.setRedirectResponseBlock { (connection: NSURLConnection!, request: NSURLRequest!, response: NSURLResponse!) -> NSURLRequest! in
            // response is not nil only if redirection occurs
            if response != nil {
                error=NSError(domain: NSPOSIXErrorDomain, code: 301, userInfo: ["location" : request.URL!.absoluteString!])
                if callback != nil {
                    
                    callback!(responseData: nil, error: error)
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            return response == nil ? request : nil
        }
        
        requestOperation.responseSerializer=AFHTTPResponseSerializer() //.acceptableContentTypes=["text/html"]
        requestOperation.start()
        
        if callback == nil {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            
            //requestOperation.waitUntilFinished()
            if error != nil {
                return error
            } else {
                switch requestOperation.response.statusCode {
                case 200:
                    return requestOperation.responseData
                case 301, 302:
                    var locationObject: AnyObject? = requestOperation.response.allHeaderFields["Location"]
                    var locationString = (locationObject==nil) ? "" : (locationObject! as! String)
                    return NSError(domain: NSPOSIXErrorDomain, code: requestOperation.response.statusCode, userInfo: ["location" : locationString])
                default:
                    return requestOperation.error
                }
            }
        }
        
        return nil
    }
    
    private func fetchPageAsString(url:String, callback: ((responseString: String?, error: NSError?) -> Void)?, referer: String?) -> AnyObject? {
        return self.fetchPageAsString(url, callback: callback, referer: referer, allowRedirect: false)
    }
    
    private func fetchPageAsString(url:String, callback: ((responseString: String?, error: NSError?) -> Void)?, referer: String?, allowRedirect: Bool) -> AnyObject? {
        let returnValue: AnyObject? = self.fetchPage(url, callback: callback==nil ? nil : { (responseData, error) -> Void in
            if error != nil {
                if callback != nil {
                    callback!(responseString: nil, error: error)
                }
            } else {
                var str: String = NSString(data: responseData!, encoding: NSUTF8StringEncoding)! as! String
                if callback != nil {
                    callback!(responseString: str, error: nil)
                }
            }
        }, referer: referer, allowRedirect: allowRedirect)!
        
        if callback == nil {
            if returnValue is NSData {
                return NSString(data: (returnValue as! NSData) as NSData, encoding: NSUTF8StringEncoding) as? String
            } else {
                return returnValue
            }
        }
        
        return nil
    }
    
    private func fetchRoot(callback: ((result: Bool) -> Void)?) -> Bool{
        let returnObject: AnyObject? = self.fetchPageAsString("/", callback: nil, referer: nil)
        var retVal: Bool = false
        
        if returnObject is String {
            let responseString: String = returnObject! as! String
            
            if responseString.rangeOfString("login.php") != nil {
                
                // let returnObject: AnyObject? = self.fetchPageAsString("/" + self.lang + "/login.php", callback: nil, referer: nil)
                let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults();
                var reallang: String? = userDefaults.objectForKey("lang") as? String;
                
                if reallang == nil {
                    // reallang = NSLocale.preferredLanguages()[0] as! String == "zh" ? "CHI" : "ENG"
                    reallang = NSLocale.currentLocale().localeIdentifier.hasPrefix("zh") ? "CHI" : "ENG"
                }
                // reallang = "CHI" // FIXME
                
                let returnObject: AnyObject? = self.fetchPageAsString("/"+self.lang+"/setlang\(reallang!).php", callback: nil, referer: nil)
                /*
                if returnObject is String {
                    retVal = (returnObject! as! String).rangeOfString("checklogin.php") != nil
                }*/
                if returnObject is NSError {
                    let error: NSError = returnObject! as! NSError
                    if (error.code / 100 == 3) && (error.userInfo!["location"]! as! String).rangeOfString("_fail.php") == nil {
                        retVal = true
                    }
                }
            }
        }
        
        if callback != nil { callback!(result: retVal) }
        return retVal
    }
    
    private func hashCode(password: String) -> String {
        let salt = "1fd49003"
        let one = "\u{1}" //NSString(bytes: &byte, length: 1, encoding: NSUTF32LittleEndianStringEncoding)! as! String
        var outPassword = String(password)
        
        if count(password) < 8 {
            for i in count(password)...7 {
                outPassword += one
            }
        }
        
        var input = salt + outPassword
        
        for i in count(input)...62 {
            input += one
        }
        
        let md5 = input.MD5()
        return salt + md5
    }
    
    private func getCookie(key: String, value: String) -> NSHTTPCookie {
        return NSHTTPCookie(properties: [
            NSHTTPCookieName: key,
            NSHTTPCookieValue: value,
            NSHTTPCookieDomain: "irec.magictv.com",
            NSHTTPCookieOriginURL: "irec.magictv.com",
            NSHTTPCookiePath: "/",
            NSHTTPCookieVersion: "0"
            ])!
        
    }
    
    private func isDirectedToLogin(error: NSError) -> Bool {
        if error.code / 100 == 3 {
            let location: String? = error.userInfo!["location"] as? String
            return location != nil && location!.rangeOfString("login") != nil
        }
        return false
    }
    
    private func login(callback: ((result: Bool) -> Void)?) -> Bool {
        let userDefaults: NSUserDefaults = NSUserDefaults()
        let username: String? = userDefaults.objectForKey("username") as? String
        let password: String? = userDefaults.objectForKey("password") as? String
        
        loggedIn=false
        
        if username == nil || password == nil {
            if callback != nil {
                callback!(result: false)
            }
            return false
        }
        let startIndex = advance(password!.startIndex, 1)
        let data: NSData = NSData(base64EncodedString: password!.substringFromIndex(startIndex), options: nil)!
        
        let password2: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        let hash: String = self.hashCode(password2)
        var retVal: Bool = false
        
        if (self.fetchRoot(nil)) {
            var cookieStorage: NSHTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
            cookieStorage.setCookie(self.getCookie("rememberdetails", value: "false"))
            cookieStorage.setCookie(self.getCookie("cookname", value: ""))
            cookieStorage.setCookie(self.getCookie("cookpass", value: ""))
            
            let returnObject: AnyObject? = self.fetchPage("/\(self.lang)/checklogin.php?myusername=\(username!)&hash_code="+hash, callback: nil, referer: "http://irec.magictv.com/\(self.lang)/login.php")
            
            if returnObject is NSError {
                let error: NSError = returnObject! as! NSError
                
                if error.code / 100 == 3 {
                    self.loggedIn = true
                    retVal = true
                }
            }
        }
        
        if callback != nil { callback!(result: retVal) }
        return retVal
    }
    
    class func setLoginDetails(username: String, password: String) {
        var userDefaults: NSUserDefaults = NSUserDefaults()
        userDefaults.setObject(username, forKey: "username")
        userDefaults.setObject("S" + password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!.base64EncodedStringWithOptions(nil), forKey: "password")
        userDefaults.synchronize()
    }
    
    func resetLogin() {
        self.loggedIn=false;
        
        var cookieStorage: NSHTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        for cookie:NSHTTPCookie in cookieStorage.cookies as! Array<NSHTTPCookie>! {
            cookieStorage.deleteCookie(cookie)
        }
        
    }
    
    func getChannelList(callback: (objectType: ObjectType, result: AnyObject?) -> Void) {
        MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate!.window!, animated: true).removeFromSuperViewOnHide=true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            for c in 0...1 {
                var payload: AnyObject?
                
                if !self.loggedIn {
                    payload = NSError(domain: NSPOSIXErrorDomain, code: 302, userInfo: ["location" : "login.php"])
                } else {
                    if self.MOCK {
                        //let payload: String = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("channel-list.php#jump", ofType: "", inDirectory: "mock"), encoding: NSUTF8StringEncoding, error: nil)
                        payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("channel-list.php#jump", ofType: nil, inDirectory: "mock")!)
                    } else {
                        payload = self.fetchPage("/\(self.lang)/channel-list.php#jump", callback: nil, referer: "\(self.host)/\(self.lang)/login.php")
                    }
                }
                
                if payload != nil {
                    if payload is NSData {
                        let document: HTMLDocument = HTMLDocument(data: payload! as! NSData, contentTypeHeader: "")
                        let channels: Array<Channel> = self.parseChannelList(document)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            callback(objectType: ObjectType.CHANNELS, result: channels)
                        })
                        break;
                    } else if payload is NSError {
                        if self.isDirectedToLogin(payload! as! NSError) {
                            if c==1 || !self.login(nil) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    callback(objectType: ObjectType.ERROR, result: nil)
                                })
                                break
                            }
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                MBProgressHUD.hideAllHUDsForView(UIApplication.sharedApplication().delegate!.window!, animated: true)
            })
        })
    }
    
    private func parseChannelList(document: HTMLDocument) -> Array<Channel> {
        var element: HTMLElement = document.firstNodeMatchingSelector("div#toplinks > ul > li > a")
        
        let unit: String = element.textContent
        
        var userDefaults: NSUserDefaults = NSUserDefaults()
        
        userDefaults.setObject(unit, forKey: "device")
        userDefaults.synchronize()
        
        element = document.firstNodeMatchingSelector("ul#channellist")
        
        var channels: Array<Channel> = []
        
        element.children.enumerateObjectsUsingBlock { (li, idx, stop) -> Void in
            if li is HTMLElement {
                let channel = Channel(element: li as! HTMLElement)
                channels.append(channel)
                println(channel)
            }
        }
        
        return channels
    }
    
    func getProgrammeList(url: String, callback: (objectType: ObjectType, result: AnyObject?) -> Void) {
        MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate!.window!, animated: true).removeFromSuperViewOnHide=true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            for c in 0...1 {
                var payload: AnyObject?
                
                if !self.loggedIn {
                    payload = NSError(domain: NSPOSIXErrorDomain, code: 302, userInfo: ["location" : "login.php"])
                } else {
                    if self.MOCK {
                        //let payload: String = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("channel-list.php#jump", ofType: "", inDirectory: "mock"), encoding: NSUTF8StringEncoding, error: nil)
                        payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("programme-list.php#jump", ofType: nil, inDirectory: "mock")!)
                    } else {
                        payload = self.fetchPage("/\(self.lang)/\(url)", callback: nil, referer: "\(self.host)/\(self.lang)/login.php")
                    }
                }
                
                if payload != nil {
                    if payload is NSData {
                        let document: HTMLDocument = HTMLDocument(data: payload! as! NSData, contentTypeHeader: "")
                        let channels: Array<Programme> = self.parseProgrammeList(document)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            callback(objectType: ObjectType.PROGRAMMES, result: channels)
                        })
                        break;
                    } else if payload is NSError {
                        if self.isDirectedToLogin(payload! as! NSError) {
                            if c==1 || !self.login(nil) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    callback(objectType: ObjectType.ERROR, result: nil)
                                })
                                break
                            }
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                MBProgressHUD.hideAllHUDsForView(UIApplication.sharedApplication().delegate!.window!, animated: true)
            })
        })
    }
    
    private func parseProgrammeList(document: HTMLDocument) -> Array<Programme> {
        var element: HTMLElement = document.firstNodeMatchingSelector("div#toplinks > ul > li > a")
        
        element = document.firstNodeMatchingSelector("ul#proglist")
        
        var programmes: Array<Programme> = []
        
        element.children.enumerateObjectsUsingBlock { (li, idx, stop) -> Void in
            if li is HTMLElement {
                let programme = Programme(element: li as! HTMLElement)
                programmes.append(programme)
                Programme.lastProgramme = programme
                println(programme)
            }
        }
        
        return programmes
    }
    
    func performGenericURL(var url: String, callback: (objectType: ObjectType, result: AnyObject?) -> Void) {
        MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate!.window!, animated: true).removeFromSuperViewOnHide=true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            var c: Int = 0
            
            /*for c in 0...1*/ while c < 2 {
                var payload: AnyObject?
                
                if !self.loggedIn {
                    payload = NSError(domain: NSPOSIXErrorDomain, code: 302, userInfo: ["location" : "login.php"])
                } else {
                    if self.MOCK {
                        //                             String filename=url.substring(url.lastIndexOf('/') + 1);
                        // if (filename.contains("?")) filename=filename.substring(0,filename.indexOf('?'));
                        
                        // document = Jsoup.parse(context.getAssets().open(filename), "UTF-8", "http://127.0.0.1");
                        var filename: String = url
                        
                        if url.rangeOfString("/") != nil {
                            filename = url.substringFromIndex(advance(url.rangeOfString("/", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil)!.startIndex, 1))
                        }
                        
                        if filename.rangeOfString("?") != nil {
                            filename = filename.substringToIndex(filename.rangeOfString("?")!.startIndex)
                        }
                        
                        payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(filename, ofType: nil, inDirectory: "mock")!)

                        // payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("programme-list.php#jump", ofType: nil, inDirectory: "mock")!)
                    } else {
                        payload = self.fetchPage("/\(self.lang)/\(url)", callback: nil, referer: "\(self.host)/\(self.lang)/login.php")
                    }
                }
                
                if payload != nil {
                    if payload is NSData {
                        let document: HTMLDocument = HTMLDocument(data: payload! as! NSData, contentTypeHeader: "")
                        /*
                        let channels: Array<Programme> = self.parseProgrammeList(document)
                        
                        callback(objectType: ObjectType.PROGRAMMES, result: channels)*/
                        
                        let links: Array<Href> = self.parseHrefList(document)
                        
                        if links.count > 0 {
                            if links[0].href.rangeOfString("programme-list.php?channelsel=") != nil {
                                // Success
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    callback(objectType: ObjectType.EMPTY, result: nil)
                                })
                                break
                            } else if (links.count == 1) {
                                url = links[0].href
                                continue
                            }
                        } else {
                            NSException.raise("Bad response", format: "links.length==0!", arguments: getVaList([]))
                        }
                        
                        let info: Array<String>? = IRecLibrary.parseProgrammeInfo(document)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            callback(objectType: ObjectType.HREF, result: [ info ?? [], links ])
                        })
                        break
                    } else if payload is NSError {
                        let error: NSError = payload! as! NSError
                        if self.isDirectedToLogin(error) {
                            if c==1 || !self.login(nil) {
                                callback(objectType: ObjectType.ERROR, result: nil)
                                break
                            }
                        } else if error.code / 100 == 3 {
                            url = (error.userInfo!["location"] as! String)
                            let range: Range<String.Index>? = url.rangeOfString("/", options: NSStringCompareOptions.BackwardsSearch)
                            
                            if range != nil {
                                url = url.substringFromIndex(advance(range!.startIndex, 1))
                            }
                            
                            println("Redirect to " + url)
                            continue
                        }
                    }
                }
                
                c++
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                MBProgressHUD.hideAllHUDsForView(UIApplication.sharedApplication().delegate!.window!, animated: true)
            })
        })
    }
    
    private func parseHrefList(document: HTMLDocument) -> Array<Href> {
        let elements: Array<HTMLElement> = document.nodesMatchingSelector("div")! as! Array<HTMLElement>
        
        var links: Array<Href> = []
        var id: String?
        var href: Href
        
        for element: HTMLElement in elements {
            id = element.attributes["id"] as? String
            if id != nil && id!.hasSuffix("options") && element.tagName.lowercaseString == "div" {
                let elements2: Array<HTMLElement> = element.nodesMatchingSelector("ul > li") as! Array<HTMLElement>
                for element2: HTMLElement in elements2 {
                    href = Href(element: element2)
                    links.append(href)
                    println(href.toString()+": \(href.href)")
                }
            }
        }
        
        return links
    }

    func getProgrammeInfo(url: String, callback: (objectType: ObjectType, result: AnyObject?) -> Void) {
        MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate!.window!, animated: true).removeFromSuperViewOnHide=true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            for c in 0...1 {
                var payload: AnyObject?
                
                if !self.loggedIn {
                    payload = NSError(domain: NSPOSIXErrorDomain, code: 302, userInfo: ["location" : "login.php"])
                } else {
                    if self.MOCK {
                        //let payload: String = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("channel-list.php#jump", ofType: "", inDirectory: "mock"), encoding: NSUTF8StringEncoding, error: nil)
                        payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("programme-info.php_success", ofType: nil, inDirectory: "mock")!)
                    } else {
                        payload = self.fetchPage("/\(self.lang)/\(url)", callback: nil, referer: "\(self.host)/\(self.lang)/login.php")
                    }
                }
                
                if payload != nil {
                    if payload is NSData {
                        let document: HTMLDocument = HTMLDocument(data: payload! as! NSData, contentTypeHeader: "")
                        let channels: Array<String>? = IRecLibrary.parseProgrammeInfo(document)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            callback(objectType: ObjectType.PROGRAMMEINFO, result: channels)
                        })
                        break
                    } else if payload is NSError {
                        if self.isDirectedToLogin(payload! as! NSError) {
                            if c==1 || !self.login(nil) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    callback(objectType: ObjectType.ERROR, result: nil)
                                })
                                break
                            }
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                MBProgressHUD.hideAllHUDsForView(UIApplication.sharedApplication().delegate!.window!, animated: true)
            })
        })
    }
    
    private class func parseProgrammeInfo(document: HTMLDocument) -> Array<String>? {
        var element: HTMLElement? = document.nodesMatchingSelector("div#proghead").first as? HTMLElement
        
        if element == nil {
            return nil
        }
        
        var info: Array<String> = []
        
        for c:UInt in 0...2 {
            info.append(element!.childAtIndex(c * 2 + 1)!.textContent)
        }
        
        element = document.nodesMatchingSelector("div#proginfo").first as? HTMLElement
        
        if element == nil {
            info.append("")
        } else {
            info.append(element!.textContent)
        }
        
        return info
    }
    
    func changeDevice(var url: String, callback: (objectType: ObjectType, result: AnyObject?) -> Void) {
        MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate!.window!, animated: true).removeFromSuperViewOnHide=true
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            for c in 0...1 {
                var payload: AnyObject?
                
                if !self.loggedIn {
                    payload = NSError(domain: NSPOSIXErrorDomain, code: 302, userInfo: ["location" : "login.php"])
                } else {
                    if self.MOCK {
                        //let payload: String = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("channel-list.php#jump", ofType: "", inDirectory: "mock"), encoding: NSUTF8StringEncoding, error: nil)
                        payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(url.lastPathComponent, ofType: nil, inDirectory: "mock")!)
                    } else {
                        payload = self.fetchPage("/\(self.lang)/\(url)", callback: nil, referer: "\(self.host)/\(self.lang)/unit-list.php")
                    }
                }
                
                if payload != nil {
                    if payload is NSError {
                        let error: NSError = payload! as! NSError
                        if self.isDirectedToLogin(error) {
                            if c==1 || !self.login(nil) {
                                callback(objectType: ObjectType.ERROR, result: nil)
                                break
                            }
                        } else if error.code / 100 == 3 {
                            url = (error.userInfo!["location"] as! String)

                            var range: Range<String.Index>? = url.rangeOfString("set_regname.php", options: NSStringCompareOptions.BackwardsSearch)
                            
                            if range != nil {
                                continue
                            }
                            
                            range = url.rangeOfString("channel-list.php", options: NSStringCompareOptions.BackwardsSearch)
                            
                            if range != nil {
                                callback(objectType: ObjectType.EMPTY, result: nil)
                            }
                            
                            break
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                MBProgressHUD.hideAllHUDsForView(UIApplication.sharedApplication().delegate!.window!, animated: true)
            })
        })
    }
    
    func getUnitList(callback: (objectType: ObjectType, result: AnyObject?) -> Void) {
        MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate!.window!, animated: true).removeFromSuperViewOnHide=true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            for c in 0...1 {
                var payload: AnyObject?
                
                if !self.loggedIn {
                    payload = NSError(domain: NSPOSIXErrorDomain, code: 302, userInfo: ["location" : "login.php"])
                } else {
                    if self.MOCK {
                        //let payload: String = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("channel-list.php#jump", ofType: "", inDirectory: "mock"), encoding: NSUTF8StringEncoding, error: nil)
                        payload = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("unit-list.php", ofType: nil, inDirectory: "mock")!)
                    } else {
                        payload = self.fetchPage("/\(self.lang)/unit-list.php", callback: nil, referer: "\(self.host)/\(self.lang)/login.php")
                    }
                }
                
                if payload != nil {
                    if payload is NSData {
                        let document: HTMLDocument = HTMLDocument(data: payload! as! NSData, contentTypeHeader: "")
                        let devices: Array<Device>? = self.parseDeviceList(document)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            callback(objectType: ObjectType.DEVICES, result: devices)
                        })
                        break;
                    } else if payload is NSError {
                        if self.isDirectedToLogin(payload! as! NSError) {
                            if c==1 || !self.login(nil) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    callback(objectType: ObjectType.ERROR, result: nil)
                                })
                                break
                            }
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                MBProgressHUD.hideAllHUDsForView(UIApplication.sharedApplication().delegate!.window!, animated: true)
            })
        })
    }

    private func parseDeviceList(document: HTMLDocument) -> Array<Device> {
        let element: HTMLElement = (document.nodesMatchingSelector("ul#channellist")! as! Array<HTMLElement>).first!
        
        var devices: Array<Device> = []
        var device: Device;
        
        for element2: HTMLElement in element.childElementNodes as! Array<HTMLElement> {
            device=Device(element: element2)
            devices.append(device)
            
            println(device)
        }
        
        return devices
    }
}


