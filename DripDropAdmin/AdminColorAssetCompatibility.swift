//
//  AdminColorAssetCompatibility.swift
//  DripDropAdmin
//

import SwiftUI

extension Color {
    static let bronze = Color(red: 205.0 / 255.0, green: 127.0 / 255.0, blue: 50.0 / 255.0)
    static let gold = Color(red: 212.0 / 255.0, green: 175.0 / 255.0, blue: 55.0 / 255.0)
    static let other = Color(red: 228.0 / 255.0, green: 230.0 / 255.0, blue: 230.0 / 255.0)
    static let realYellow = Color(red: 255.0 / 255.0, green: 226.0 / 255.0, blue: 0.0 / 255.0)
    static let silver = Color(red: 192.0 / 255.0, green: 192.0 / 255.0, blue: 192.0 / 255.0)
    static let textFieldPrompt = Color(red: 25.0 / 255.0, green: 25.0 / 255.0, blue: 25.0 / 255.0)
    static let defaultBackground = Color(red: 25.0 / 255.0, green: 25.0 / 255.0, blue: 25.0 / 255.0)
    static let font = Color(red: 25.0 / 255.0, green: 25.0 / 255.0, blue: 25.0 / 255.0)
    static let header = Color(red: 147.0 / 255.0, green: 163.0 / 255.0, blue: 177.0 / 255.0)
    static let lightBlue = Color(red: 29.0 / 255.0, green: 46.0 / 255.0, blue: 118.0 / 255.0)
    static let list = Color(red: 25.0 / 255.0, green: 25.0 / 255.0, blue: 25.0 / 255.0)
    static let poolGreen = Color(red: 43.0 / 255.0, green: 96.0 / 255.0, blue: 15.0 / 255.0)
    static let poolRed = Color(red: 156.0 / 255.0, green: 13.0 / 255.0, blue: 56.0 / 255.0)
    static let poolYellow = Color(red: 205.0 / 255.0, green: 192.0 / 255.0, blue: 123.0 / 255.0)
    static let poolWhite = Color(red: 227.0 / 255.0, green: 230.0 / 255.0, blue: 230.0 / 255.0)
    static let poolBlack = Color(red: 25.0 / 255.0, green: 25.0 / 255.0, blue: 25.0 / 255.0)
    static let poolBlue = Color(red: 29.0 / 255.0, green: 46.0 / 255.0, blue: 118.0 / 255.0)
    static let poolGray = Color(red: 145.0 / 255.0, green: 148.0 / 255.0, blue: 148.0 / 255.0)
    static let darkGray = Color(red: 84.0 / 255.0, green: 85.0 / 255.0, blue: 85.0 / 255.0)
}

extension ShapeStyle where Self == Color {
    static var bronze: Color { .bronze }
    static var gold: Color { .gold }
    static var other: Color { .other }
    static var realYellow: Color { .realYellow }
    static var silver: Color { .silver }
    static var textFieldPrompt: Color { .textFieldPrompt }
    static var defaultBackground: Color { .defaultBackground }
    static var font: Color { .font }
    static var header: Color { .header }
    static var lightBlue: Color { .lightBlue }
    static var list: Color { .list }
    static var poolGreen: Color { .poolGreen }
    static var poolRed: Color { .poolRed }
    static var poolYellow: Color { .poolYellow }
    static var poolWhite: Color { .poolWhite }
    static var poolBlack: Color { .poolBlack }
    static var poolBlue: Color { .poolBlue }
    static var poolGray: Color { .poolGray }
    static var darkGray: Color { .darkGray }
}
