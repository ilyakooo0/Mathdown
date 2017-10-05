//
//  main.swift
//  Mathdown
//
//  Created by Ilya Kos on 9/13/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import Foundation

typealias Lines = [String]
typealias Element = [String]
let commentChars = CharacterSet.init(charactersIn: "#/")
let styleCharecters = CharacterSet.init(charactersIn: "_*")


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
            case "-b:s":
                style = .square
            case "-b:r":
                style = .round
            case "-b:l":
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

func process(element: Element) -> String {
    var out = ""
    
    var inMatrix = false
    var first = false
    var seperated = false
    var afterSeparator: [Substring] = []
    
    var small = false
    
    let arrows = CharacterSet.init(charactersIn: "⟺⟷⟼⟻⟶⟹⟵⟸")
    
    let nEl = element.map { (el) -> String in
        switch el {
        case let l where l.last == ">" && l.first == "<" && l.dropLast().dropFirst().filter({$0 == "="}).count > 0:
            small = true
            return "⟺"
        case let l where l.last == ">" && l.first == "<" && l.dropLast().dropFirst().filter({$0 == "-"}).count > 0:
            small = true
            return "⟷"
        case let l where l.last == ">" && l.first == "|" && l.dropLast().dropFirst().filter({$0 == "-"}).count > 0:
            small = true
            return "⟼"
        case let l where l.last == "|" && l.first == "<" && l.dropLast().dropFirst().filter({$0 == "-"}).count > 0:
            small = true
            return "⟻"
        case let l where l.last == ">" && l.dropLast().filter({$0 == "-"}).count > 0:
            small = true
            return "⟶"
        case let l where l.last == ">" && l.dropLast().filter({$0 == "="}).count > 0:
            small = true
            return "⟹"
        case let l where l.first == "<" && l.dropFirst().filter({$0 == "-"}).count > 0:
            small = true
            return "⟵"
        case let l where l.first == "<" && l.dropFirst().filter({$0 == "="}).count > 0:
            small = true
            return "⟸"
        default:
            return el
        }
    }
    
    func process(lineElement: Substring, withAttributes attributes: String = "", style: ElementStyle = .none) -> Substring {
        func extractNextElement(from line: Substring) -> (element: Substring, left: Substring) {
            if line.first != "(" {
                var i = line.startIndex
                var el: Substring = ""
                while i < line.endIndex && CharacterSet.alphanumerics.contains(line[i].unicodeScalars.first!) {
                    el.append(line[i])
                    i = line.index(after: i)
                }
                return (el, line[i...])
            } else {
                var brackets = 0
                var i = line.startIndex
                var el: Substring = ""
                while i < line.endIndex {
                    switch el[i] {
                    case "(":
                        brackets += 1
                    case ")":
                        brackets -= 1
                    default:
                        break
                    }
                    i = line.index(after: i)
                    if brackets == 0 {
                        break
                    }
                    el.append(el[i])
                }
                if brackets != 0 {
                    print("Mismatched brackets")
                    exit(0)
                }
                return (el.dropFirst(), line[i...])
            }
        }
        var i = lineElement.startIndex
        while i < lineElement.endIndex {
            switch lineElement[i] {
            case "^":
                let parts = extractNextElement(from: lineElement[lineElement.index(after: i)...])
                return "<mo mathvariant=\"\(style.rawValue)\" \(attributes)>\(lineElement[..<i].filter({$0 != "\\"}))</mo>" + "<msup><mo></mo><mn>\(parts.element)</mn></msup>" + process(lineElement: parts.left, withAttributes: attributes, style: style)
            case "!":
                let parts = extractNextElement(from: lineElement[lineElement.index(after: i)...])
                return "<mo mathvariant=\"\(style.rawValue)\" \(attributes)>\(lineElement[..<i].filter({$0 != "\\"}))</mo>" + "<mover accent=\"true\"><mrow><mo>\(parts.element)</mo></mrow><mo>_</mo></mover>" + process(lineElement: parts.left, withAttributes: attributes, style: style)
            case "\\":
                i = lineElement.index(after: i)
            case "/":
                let parts = extractNextElement(from: lineElement[lineElement.index(after: i)...])
                return "<mo mathvariant=\"\(style.rawValue)\" \(attributes)>\(lineElement[..<i].filter({$0 != "\\"}))</mo>" + "<msub><mo></mo><mn>\(parts.element)</mn></msub>" + process(lineElement: parts.left, withAttributes: attributes, style: style)
            default:
                break
            }
            i = lineElement.index(after: i)
        }
        return Substring("<mo mathvariant=\"\(style.rawValue)\" \(attributes)>\(lineElement.filter({$0 != "\\"}))</mo>")
    }
    func process(line: Substring) {
        out.append("<mtr>")
        for element in line.split(
            whereSeparator: {c in CharacterSet.whitespaces.contains(c.unicodeScalars.first!)}) {
                switch element {
                case "_":
                    out.append("<mtd><mspace height=\"0.8em\"/></mtd>")
                default:
                    let eStyle = element.style
                    out.append("<mtd>\(process(lineElement: Substring(element.trimmingStyleCharecters()), withAttributes: "height=\"0.8em\"", style: eStyle))</mtd>")
                }
        }
        out.append("</mtr>")
    }
    func process(comment: String) {
        if comment.hasPrefix("#") {
            out.append("<!-- \(comment.trimmingCharacters(in: commentChars).trimmingCharacters(in: .whitespaces)) -->")
        }
    }

    for line in nEl {
        if inMatrix {
            if first && line.contains("|") {
                seperated = true
            }
            switch line {
            case "]":
                if seperated {
                    out.append("</mtable><mo stretchy=\"true\">|</mo><mtable>")
                    for line in afterSeparator {
                        process(line: line)
                    }
                }
                out.append("</mtable><mo stretchy=\"true\">\(style.closing)</mo></mrow></mtd></mtr>")
                inMatrix = false
                seperated = false
                afterSeparator = []
            default:
                if seperated {
                    let split = line.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
                    if split.count != 2 {
                        print("Inconsistent syntax. The `|` seperator isn't consistent within a matrix.")
                        exit(0)
                    }
                    process(line: split[0])
                    afterSeparator.append(split[1])
                } else {
                    process(line: Substring(line))
                }
            }
        } else {
            switch line {
            case let l where l.hasPrefix("//"):
                break
            case let l where l.hasPrefix("#"):
                out.append("</mtable></math>\n\n")
                process(comment: l)
                out.append("\n\n<math><mtable>")
                break // TODO: Figure out what to do
            case "[":
                out.append("<mtr><mtd><mrow><mo stretchy=\"true\">\(style.opening)</mo><mtable>")
                inMatrix = true
                first = true
                continue
            case "":
                if !first {
                    out.append("</mtable><mtable>")
                }
                first = true
                continue
            case let l where arrows.contains(l.first!.unicodeScalars.first!):
                out.append("<mtr><mtd><mo>\(line)</mo></mtd></mtr>")
            default:
                out.append("<mtr><mtd>\(small ? "<mstyle scriptlevel=\"1\">" : "")\(process(lineElement: Substring(line)))\(small ? "</mstyle>" : "")</mtd></mtr>")
            }
        }
        first = false
    }
    return out
}

func process(mth: String) -> String {
    let elements = mth
        .split(separator: "\n", omittingEmptySubsequences: false)
        .map({$0.trimmingCharacters(in: .whitespaces)})
        .map({ l in
            var i = l.startIndex
            for u in 0..<max(0, l.count - 1) {
                if l[i] == "/" && l[l.index(after: i)] == "/" {
                    return String(l.dropLast(l.count - u))
                }
                i = l.index(after: i)
            }
            return l
        })
        .split(separator: "")
    var out = "<math><mtable>"
    for el in elements {
        out.append(process(element: Array(el)))
        out.append("</mtable><mtable>")
    }
    out.append("</mtable></math>")
    return out
}

do {
    let inp = try String.init(contentsOf: inputUrl)
    try process(mth: inp).write(to: outputUrl, atomically: true, encoding: .utf8)
} catch {
    print("Invalid file")
}
