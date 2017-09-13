//
//  main.swift
//  Mathdown
//
//  Created by Ilya Kos on 9/13/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import Foundation

enum BracketStyle {
    case square
    case round
    var opening: Character {
        switch self {
        case .round:
            return "("
        case .square:
            return "["
        }
    }
    var closing: Character {
        switch self {
        case .round:
            return ")"
        case .square:
            return "]"
        }
    }
}

var style: BracketStyle = .round
var outputUrl: URL!
var inputUrl: URL! {
    didSet {
        outputUrl = outputUrl ?? inputUrl.deletingPathExtension().appendingPathExtension("xml")
    }
}

var args = CommandLine.arguments.dropFirst()
switch args.count {
case 0:
    print("You didn't provide an input file")
    exit(0)
case 1:
    inputUrl = URL(fileURLWithPath: args.first!)
default:
    func processArgs() {
        if let arg = args.popFirst() {
            switch arg {
            case "-i":
                if let surl = args.popFirst() {
                    inputUrl = URL(fileURLWithPath: surl)
                }
            case "-o":
                if let surl = args.popFirst() {
                    outputUrl = URL(fileURLWithPath: surl)
                }
            case "-s":
                style = .square
            case "-r":
                style = .round
            default:
                return
            }
            processArgs()
        }
    }
    processArgs()
}
enum ElementStyle: String {
    case none = ""
    case bold = "bold"
    case italic = "italic"
    case boldItalic = "bold-italic"
}
let styleCharecters = CharacterSet.init(charactersIn: "_*")
extension String.SubSequence {
    var style: ElementStyle {
        let num = self.prefix(while: {styleCharecters.contains($0.unicodeScalars.first!)}).count
        switch num {
        case 0:
            return .none
        case 1:
            return .italic
        case 2:
            return .bold
        default:
            return .boldItalic
        }
    }
    func trimmingStyleCharecters() -> String {
        return self.trimmingCharacters(in: styleCharecters)
    }
}
func process(mth: String) -> String {
    let whitespace = CharacterSet.whitespaces
    
    var out = "<math>"
    let lines = mth.split(separator: "\n", omittingEmptySubsequences: false)
        .map {$0.trimmingCharacters(in: .whitespaces)}
    var insideMatrix = false
    for line in lines {
        switch line {
        case "":
            if insideMatrix {
                out.append("</mtable><mo>\(style.closing)</mo></mrow>")
                insideMatrix = false
            }
        default:
            if !insideMatrix {
                out.append("<mrow><mo>\(style.opening)</mo><mtable>")
                insideMatrix = true
            }
            out.append("<mtr>")
            for element in line.split(
                whereSeparator: {c in whitespace.contains(c.unicodeScalars.first!)}) {
                    let eStyle = element.style
                    out.append("<mtd><mn mathvariant=\"\(eStyle.rawValue)\">\(element.trimmingStyleCharecters())</mn></mtd>")
            }
            out.append("</mtr>")
        }
    }
    if insideMatrix {
        out.append("</mtable><mo>\(style.closing)</mo></mrow>")
    }
    out.append("</math>")
    return out
}

do {
    let inp = try String.init(contentsOf: inputUrl)
    try process(mth: inp).write(to: outputUrl, atomically: true, encoding: .utf8)
} catch {
    print("Invalid file")
}
