//
//  ViewController.swift
//  Signed Comment
//
//  Created by hsoi on 11/13/16.
//  Copyright © 2016 Hsoi Enterprises LLC. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    // Hsoi 2016-12-29 - I've been away from macOS programming for some time, so please enlighten me if there's a better way.
    //
    // I wanted to use NSUserDefaultsController and Cocoa Bindings to make the UI go -- and it does. But it seems to
    // share data between the app and extension you have to use "user default suites", and there's no way to make
    // that happen with NSUserDefaultsController. 
    //
    // So... this app isn't anything heavyweight. What I opted to do was continue to use NSUserDefaultsController
    // for the UI, then when a value changes, just transpose it into my suite user defaults. No it's not really
    // a great way to do things, but this whole Xcode extension is simply a way for me to have a rebirth of
    // functionality I had ages ago and make my life a little easier. So, I can live with the hack.
    
    
    private let groupUserDefaults = UserDefaults(suiteName: "4WUC25D9BH.com.hsoienterprises.SignedComment")
    private var observerContext = 0
    
    deinit {
        NSUserDefaultsController.shared().removeObserver(self, forKeyPath: "values.\(PrefKeys.commenterName.rawValue)", context: &observerContext)
        NSUserDefaultsController.shared().removeObserver(self, forKeyPath: "values.\(PrefKeys.dateFormat.rawValue)", context: &observerContext)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NSUserDefaultsController.shared().addObserver(self, forKeyPath: "values.\(PrefKeys.commenterName.rawValue)", options: .new, context: &observerContext)
        NSUserDefaultsController.shared().addObserver(self, forKeyPath: "values.\(PrefKeys.dateFormat.rawValue)", options: .new, context: &observerContext)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        switch keyPath {
        case .some("values.\(PrefKeys.commenterName.rawValue)"):
            // Hsoi 2016-12-19 - OK, what am I missing here? Why doesn't `change?[.newKey]` contain my value?
            // So, we'll just get the value directly out of the controller....            
            let fetchedValue = NSUserDefaultsController.shared().value(forKeyPath: "values.\(PrefKeys.commenterName.rawValue)")
            groupUserDefaults?.set(fetchedValue, forKey: PrefKeys.commenterName.rawValue)
        case .some("values.\(PrefKeys.dateFormat.rawValue)"):
            // Hsoi 2016-12-19 - OK, what am I missing here? Why doesn't `change?[.newKey]` contain my value?
            // So, we'll just get the value directly out of the controller....
            let fetchedValue = NSUserDefaultsController.shared().value(forKeyPath: "values.\(PrefKeys.dateFormat.rawValue)")
            groupUserDefaults?.set(fetchedValue, forKey: PrefKeys.dateFormat.rawValue)
        default:
            break
        }        
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

