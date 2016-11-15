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
        guard firstSelection.start.line == firstSelection.end.line && firstSelection.start.column == firstSelection.end.column else {
            error = ErrorCode.onlyPlainInsertionSupported.asError()
            return
        }
        
        let lineIndex = firstSelection.start.line
        
        let username = "Hsoi"   // TODO: eventually allow user customization
        
        // Hsoi 2016-09-12 FIXME: something
        // TODO: do
        
        dateFormatter.dateFormat = "yyyy-MM-dd" // TODO: eventually get this from some NSUserDefaults that allows the user to customize their desired date.
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
             "public.php-script":
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
        newSelection.end.column += commentString.characters.count
        buffer.selections[0] = newSelection
    }
    
}
