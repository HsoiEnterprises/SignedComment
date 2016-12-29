//
//  AppDelegate.swift
//  Signed Comment
//
//  Created by hsoi on 11/13/16.
//  Copyright © 2016 Hsoi Enterprises LLC. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults: [String:Any] = [
            PrefKeys.commenterName.rawValue: "Hsoi",
            PrefKeys.dateFormat.rawValue: "yyyy-MM-dd"
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

