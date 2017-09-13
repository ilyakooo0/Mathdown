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
    case line
    var opening: Character {
        switch self {
        case .round:
            return "("
        case .square:
            return "["
        case .line:
            return "|"
        }
    }
    var closing: Character {
        switch self {
        case .round:
            return ")"
        case .square:
            return "]"
        case .line:
            return "|"
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
            case "-l":
                style = .line
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
    
    var seperated = false
    var afterSeparator: [String.SubSequence] = []
    
    var out = "<math>"
    let lines = mth.split(separator: "\n", omittingEmptySubsequences: false)
        .map {$0.trimmingCharacters(in: .whitespaces)}
    var insideMatrix = false
    func pureProcess(line: Substring) {
        out.append("<mtr>")
        for element in line.split(
            whereSeparator: {c in whitespace.contains(c.unicodeScalars.first!)}) {
                switch element {
                case "_":
                    out.append("<mtd><mspace height=\"0.8em\"/></mtd>")
                default:
                    let eStyle = element.style
                    out.append("<mtd><mn mathvariant=\"\(eStyle.rawValue)\" height=\"0.8em\">\(element.trimmingStyleCharecters())</mn></mtd>")
                }
        }
        out.append("</mtr>")
    }
    func checkInsideMatrix() {
        if insideMatrix {
            if seperated {
                out.append("</mtable><mo>|</mo><mtable>")
                for line in afterSeparator {
                    pureProcess(line: line)
                }
            }
            out.append("</mtable><mo>\(style.closing)</mo></mrow>")
            insideMatrix = false
            seperated = false
            afterSeparator = []
        }
    }
    func process(line: String.SubSequence) {
        switch line {
        case "":
            checkInsideMatrix()
        default:
            if !insideMatrix {
                out.append("<mrow><mo>\(style.opening)</mo><mtable>")
                insideMatrix = true
            }
            pureProcess(line: line)
        }
        
    }
    for line in lines {
        if !insideMatrix {
            if lines.first?.contains("|") == true {
                seperated = true
            }
        }
        if line == "" {
            process(line: Substring(line))
        } else if seperated {
            let split = line.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            if split.count != 2 {
                print("Inconsistent syntax")
                exit(0)
            }
            process(line: split[0])
            afterSeparator.append(split[1])
        } else {
            process(line: Substring(line))
        }
    }
    checkInsideMatrix()
    out.append("</math>")
    return out
}

do {
    let inp = try String.init(contentsOf: inputUrl)
    try process(mth: inp).write(to: outputUrl, atomically: true, encoding: .utf8)
} catch {
    print("Invalid file")
}
