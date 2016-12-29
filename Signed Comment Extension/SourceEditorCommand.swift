//
//  SourceEditorCommand.swift
//  Comment Prefixer
//
//  Created by hsoi on 9/25/16.
//  Copyright © 2016 Hsoi Enterprises LLC. All rights reserved.
//

import Foundation
import XcodeKit


let dateFormatter = DateFormatter()

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    private enum ErrorCode: Int, CustomStringConvertible {
        
        case unsupportedSelection           =   -1
        case couldNotGetSelection           =   -2
        case onlyPlainInsertionSupported    =   -3
        case unknownUTI                     =   -4
        case unknownCommandType             =   -5
        
        var description: String {
            switch self {
            case .unsupportedSelection:
                return NSLocalizedString("Does not support multiple selections.", comment: "")
                
            case .couldNotGetSelection:
                return NSLocalizedString("Failed to obtain the selection.", comment: "")
                
            case .onlyPlainInsertionSupported:
                return NSLocalizedString("Currently only supporting plain insertion (i.e. no selection at all).", comment: "")
                
            case .unknownUTI:
                return NSLocalizedString("Unknown file type - don't know what the comment delimiter could be. Please file an issue.", comment: "")
                
            case .unknownCommandType:
                return NSLocalizedString("Unknown command type. Please file an issue.", comment: "")
            }
        }
        
        func asError() -> Error {
            return NSError(domain: "HsoiSourceEditorCommandErrorDomain", code: self.rawValue, userInfo: [NSLocalizedDescriptionKey:self.description])
        }
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        var error: Error?
        defer {
            completionHandler(error)
        }
        
        let groupUserDefaults = UserDefaults(suiteName: "4WUC25D9BH.com.hsoienterprises.SignedComment")
        
        /*
 
         notes to myself.
         
         So it seems buffer.lines contains ALL the lines of of the file... well, whatever the grand buffer is that I'm working with.
         
         then buffer.selections has the ranges... and like I selected some text and there was a range that went from "line 16, column 4" to "line 19, colulmn 5". Which
         was the actual selection.
         
         Yup. That's the thing.
         
         So it LOOKS like what I have to do, to do text manipulation is that the selections are relevative/referencing the buffer
         
         So I GUESS take the line info from the buffer, then go into the buffer.lines and manipulate what's in there with the selection information.
         
         ---
         
         Also learned that you can't directly debug. You do NOT enable "debug this executable" in the scheme -- system integrity protection
         won't let you then attach. So after you fire it all up and get the special gray Xcode running, go to Debug menu (in blue Xcode)
         and Attach to Process. You should see your extension in the list, like at the top of the list. Attach, and then it works.
         
        */
        
        let buffer = invocation.buffer
        
        // Hsoi 2016-09-25 - Only going to work with the first selection -- if there's more than 1 selection, I don't see
        // it making a lot of sense to apply this to all of them.
        guard buffer.selections.count == 1 else {
            error = ErrorCode.unsupportedSelection.asError()
            return
        }
        
        guard let firstSelection = buffer.selections.firstObject as? XCSourceTextRange else {
            error = ErrorCode.couldNotGetSelection.asError()
            return
        }
        
        // Hsoi 2016-09-25 - for now, only support "no selection". Just plain old insertion point.
        // Hsoi 2016-12-09 - Nah, let's support replacing the selected text. I find myself wanting to do this
        // enough, so let's do it. Besides, the only reason I didn't do it at first was because I was learning
        // and trying to figure out the whole process for working with the XCSourceEditorCommandInvocation
//        guard firstSelection.start.line == firstSelection.end.line && firstSelection.start.column == firstSelection.end.column else {
//            error = ErrorCode.onlyPlainInsertionSupported.asError()
//            return
//        }
        
        let lineIndex = firstSelection.start.line
        
        let username = groupUserDefaults?.string(forKey: "\(PrefKeys.commenterName.rawValue)") ?? "Hsoi"
        
        dateFormatter.dateFormat = groupUserDefaults?.string(forKey: "dateFormat") ?? "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        
        // https://developer.apple.com/library/prerelease/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
        
        // .swift   -   public.swift-source
        // .h       -   public.c-header
        // .m       -   public.objective-c-source
        // .mm      -   public.objective-c-source
        // .c       -   public.c-source
        // .cpp     -   public.c-plus-plus-source
        // .hpp     -   public.c-plus-plus-source
        // .sh      -   public.shell-script
        // .py      -   public.python-script
        // .rb      -   public.ruby-script
        
        let uti = buffer.contentUTI
        let commentPrefix: String
        switch uti {
        case "public.swift-source",
             "public.objective-c-source",
             "public.objective-c-plus-​plus-source",
             "public.c-header",
             "public.c-source",
             "public.c-plus-plus-header",
             "public.c-plus-plus-source",
             "com.sun.java-source ",
             "public.php-script",
             "com.apple.xcode.configsettings":
            commentPrefix = "//"
            
        case "public.shell-script",
             "public.python-script",
             "public.ruby-script",
             "public.perl-script":
            commentPrefix = "#"
            
        default:
            error = ErrorCode.unknownUTI.asError()
            return
        }
        
        let modifierPrefix: String
        if invocation.commandIdentifier.hasSuffix(".InsertRegular") {
            modifierPrefix = ""
        }
        else if invocation.commandIdentifier.hasSuffix(".InsertFIXME") {
            modifierPrefix = "FIXME:"
        }
        else if invocation.commandIdentifier.hasSuffix(".InsertTODO") {
            modifierPrefix = "TODO:"
        }
        else {
            error = ErrorCode.unknownCommandType.asError()
            return
        }
        
        var commentString = "\(commentPrefix)"
        if !modifierPrefix.isEmpty {
            commentString += " \(modifierPrefix)"
        }
        if !username.isEmpty {
            commentString += " \(username)"
        }
        if !dateString.isEmpty {
            commentString += " \(dateString)"
        }
        commentString += " - "
        
        
        let line = buffer.lines[lineIndex] as! NSString
        let range = NSRange(location: firstSelection.start.column, length: firstSelection.end.column - firstSelection.start.column)
        let newLine = line.replacingCharacters(in: range, with: commentString)
        buffer.lines[lineIndex] = newLine
        
        // Hsoi 2016-09-25 - move the selection to the end of what we just inserted, so the user can immediately start typing.
        let newSelection = firstSelection
        newSelection.start.column += commentString.characters.count
        newSelection.end.column = newSelection.start.column
        buffer.selections[0] = newSelection
    }
    
}
