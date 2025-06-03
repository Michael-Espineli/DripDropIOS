import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "Bronze" asset catalog color resource.
    static let bronze = ColorResource(name: "Bronze", bundle: resourceBundle)

    /// The "DarkGray" asset catalog color resource.
    static let darkGray = ColorResource(name: "DarkGray", bundle: resourceBundle)

    /// The "Gold" asset catalog color resource.
    static let gold = ColorResource(name: "Gold", bundle: resourceBundle)

    /// The "Other" asset catalog color resource.
    static let other = ColorResource(name: "Other", bundle: resourceBundle)

    /// The "RealYellow" asset catalog color resource.
    static let realYellow = ColorResource(name: "RealYellow", bundle: resourceBundle)

    /// The "Silver" asset catalog color resource.
    static let silver = ColorResource(name: "Silver", bundle: resourceBundle)

    /// The "TextFieldPrompt" asset catalog color resource.
    static let textFieldPrompt = ColorResource(name: "TextFieldPrompt", bundle: resourceBundle)

    /// The "defaultBackground" asset catalog color resource.
    static let defaultBackground = ColorResource(name: "defaultBackground", bundle: resourceBundle)

    /// The "fontColor" asset catalog color resource.
    static let font = ColorResource(name: "fontColor", bundle: resourceBundle)

    /// The "headerColor" asset catalog color resource.
    static let header = ColorResource(name: "headerColor", bundle: resourceBundle)

    /// The "lightBlue" asset catalog color resource.
    static let lightBlue = ColorResource(name: "lightBlue", bundle: resourceBundle)

    /// The "listColor" asset catalog color resource.
    static let list = ColorResource(name: "listColor", bundle: resourceBundle)

    /// The "poolBlack" asset catalog color resource.
    static let poolBlack = ColorResource(name: "poolBlack", bundle: resourceBundle)

    /// The "poolBlue" asset catalog color resource.
    static let poolBlue = ColorResource(name: "poolBlue", bundle: resourceBundle)

    /// The "poolGray" asset catalog color resource.
    static let poolGray = ColorResource(name: "poolGray", bundle: resourceBundle)

    /// The "poolGreen" asset catalog color resource.
    static let poolGreen = ColorResource(name: "poolGreen", bundle: resourceBundle)

    /// The "poolRed" asset catalog color resource.
    static let poolRed = ColorResource(name: "poolRed", bundle: resourceBundle)

    /// The "poolWhite" asset catalog color resource.
    static let poolWhite = ColorResource(name: "poolWhite", bundle: resourceBundle)

    /// The "poolYellow" asset catalog color resource.
    static let poolYellow = ColorResource(name: "poolYellow", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "DefaultPin" asset catalog image resource.
    static let defaultPin = ImageResource(name: "DefaultPin", bundle: resourceBundle)

    /// The "EndPin" asset catalog image resource.
    static let endPin = ImageResource(name: "EndPin", bundle: resourceBundle)

    /// The "StartPin" asset catalog image resource.
    static let startPin = ImageResource(name: "StartPin", bundle: resourceBundle)

    /// The "grayback" asset catalog image resource.
    static let grayback = ImageResource(name: "grayback", bundle: resourceBundle)

    /// The "pool" asset catalog image resource.
    static let pool = ImageResource(name: "pool", bundle: resourceBundle)

    /// The "pools" asset catalog image resource.
    static let pools = ImageResource(name: "pools", bundle: resourceBundle)

    /// The "zenitsu" asset catalog image resource.
    static let zenitsu = ImageResource(name: "zenitsu", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "Bronze" asset catalog color.
    static var bronze: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bronze)
#else
        .init()
#endif
    }

    #warning("The \"DarkGray\" color asset name resolves to a conflicting NSColor symbol \"darkGray\". Try renaming the asset.")

    /// The "Gold" asset catalog color.
    static var gold: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gold)
#else
        .init()
#endif
    }

    /// The "Other" asset catalog color.
    static var other: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .other)
#else
        .init()
#endif
    }

    /// The "RealYellow" asset catalog color.
    static var realYellow: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .realYellow)
#else
        .init()
#endif
    }

    /// The "Silver" asset catalog color.
    static var silver: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .silver)
#else
        .init()
#endif
    }

    /// The "TextFieldPrompt" asset catalog color.
    static var textFieldPrompt: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textFieldPrompt)
#else
        .init()
#endif
    }

    /// The "defaultBackground" asset catalog color.
    static var defaultBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .defaultBackground)
#else
        .init()
#endif
    }

    /// The "fontColor" asset catalog color.
    static var font: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .font)
#else
        .init()
#endif
    }

    /// The "headerColor" asset catalog color.
    static var header: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .header)
#else
        .init()
#endif
    }

    /// The "lightBlue" asset catalog color.
    static var lightBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightBlue)
#else
        .init()
#endif
    }

    /// The "listColor" asset catalog color.
    static var list: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .list)
#else
        .init()
#endif
    }

    /// The "poolBlack" asset catalog color.
    static var poolBlack: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolBlack)
#else
        .init()
#endif
    }

    /// The "poolBlue" asset catalog color.
    static var poolBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolBlue)
#else
        .init()
#endif
    }

    /// The "poolGray" asset catalog color.
    static var poolGray: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolGray)
#else
        .init()
#endif
    }

    /// The "poolGreen" asset catalog color.
    static var poolGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolGreen)
#else
        .init()
#endif
    }

    /// The "poolRed" asset catalog color.
    static var poolRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolRed)
#else
        .init()
#endif
    }

    /// The "poolWhite" asset catalog color.
    static var poolWhite: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolWhite)
#else
        .init()
#endif
    }

    /// The "poolYellow" asset catalog color.
    static var poolYellow: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .poolYellow)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "Bronze" asset catalog color.
    static var bronze: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bronze)
#else
        .init()
#endif
    }

    #warning("The \"DarkGray\" color asset name resolves to a conflicting UIColor symbol \"darkGray\". Try renaming the asset.")

    /// The "Gold" asset catalog color.
    static var gold: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gold)
#else
        .init()
#endif
    }

    /// The "Other" asset catalog color.
    static var other: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .other)
#else
        .init()
#endif
    }

    /// The "RealYellow" asset catalog color.
    static var realYellow: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .realYellow)
#else
        .init()
#endif
    }

    /// The "Silver" asset catalog color.
    static var silver: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .silver)
#else
        .init()
#endif
    }

    /// The "TextFieldPrompt" asset catalog color.
    static var textFieldPrompt: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textFieldPrompt)
#else
        .init()
#endif
    }

    /// The "defaultBackground" asset catalog color.
    static var defaultBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .defaultBackground)
#else
        .init()
#endif
    }

    /// The "fontColor" asset catalog color.
    static var font: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .font)
#else
        .init()
#endif
    }

    /// The "headerColor" asset catalog color.
    static var header: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .header)
#else
        .init()
#endif
    }

    /// The "lightBlue" asset catalog color.
    static var lightBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .lightBlue)
#else
        .init()
#endif
    }

    /// The "listColor" asset catalog color.
    static var list: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .list)
#else
        .init()
#endif
    }

    /// The "poolBlack" asset catalog color.
    static var poolBlack: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolBlack)
#else
        .init()
#endif
    }

    /// The "poolBlue" asset catalog color.
    static var poolBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolBlue)
#else
        .init()
#endif
    }

    /// The "poolGray" asset catalog color.
    static var poolGray: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolGray)
#else
        .init()
#endif
    }

    /// The "poolGreen" asset catalog color.
    static var poolGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolGreen)
#else
        .init()
#endif
    }

    /// The "poolRed" asset catalog color.
    static var poolRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolRed)
#else
        .init()
#endif
    }

    /// The "poolWhite" asset catalog color.
    static var poolWhite: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolWhite)
#else
        .init()
#endif
    }

    /// The "poolYellow" asset catalog color.
    static var poolYellow: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .poolYellow)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "Bronze" asset catalog color.
    static var bronze: SwiftUI.Color { .init(.bronze) }

    /// The "DarkGray" asset catalog color.
    static var darkGray: SwiftUI.Color { .init(.darkGray) }

    /// The "Gold" asset catalog color.
    static var gold: SwiftUI.Color { .init(.gold) }

    /// The "Other" asset catalog color.
    static var other: SwiftUI.Color { .init(.other) }

    /// The "RealYellow" asset catalog color.
    static var realYellow: SwiftUI.Color { .init(.realYellow) }

    /// The "Silver" asset catalog color.
    static var silver: SwiftUI.Color { .init(.silver) }

    /// The "TextFieldPrompt" asset catalog color.
    static var textFieldPrompt: SwiftUI.Color { .init(.textFieldPrompt) }

    /// The "defaultBackground" asset catalog color.
    static var defaultBackground: SwiftUI.Color { .init(.defaultBackground) }

    /// The "fontColor" asset catalog color.
    static var font: SwiftUI.Color { .init(.font) }

    /// The "headerColor" asset catalog color.
    static var header: SwiftUI.Color { .init(.header) }

    /// The "lightBlue" asset catalog color.
    static var lightBlue: SwiftUI.Color { .init(.lightBlue) }

    /// The "listColor" asset catalog color.
    static var list: SwiftUI.Color { .init(.list) }

    /// The "poolBlack" asset catalog color.
    static var poolBlack: SwiftUI.Color { .init(.poolBlack) }

    /// The "poolBlue" asset catalog color.
    static var poolBlue: SwiftUI.Color { .init(.poolBlue) }

    /// The "poolGray" asset catalog color.
    static var poolGray: SwiftUI.Color { .init(.poolGray) }

    /// The "poolGreen" asset catalog color.
    static var poolGreen: SwiftUI.Color { .init(.poolGreen) }

    /// The "poolRed" asset catalog color.
    static var poolRed: SwiftUI.Color { .init(.poolRed) }

    /// The "poolWhite" asset catalog color.
    static var poolWhite: SwiftUI.Color { .init(.poolWhite) }

    /// The "poolYellow" asset catalog color.
    static var poolYellow: SwiftUI.Color { .init(.poolYellow) }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "Bronze" asset catalog color.
    static var bronze: SwiftUI.Color { .init(.bronze) }

    /// The "DarkGray" asset catalog color.
    static var darkGray: SwiftUI.Color { .init(.darkGray) }

    /// The "Gold" asset catalog color.
    static var gold: SwiftUI.Color { .init(.gold) }

    /// The "Other" asset catalog color.
    static var other: SwiftUI.Color { .init(.other) }

    /// The "RealYellow" asset catalog color.
    static var realYellow: SwiftUI.Color { .init(.realYellow) }

    /// The "Silver" asset catalog color.
    static var silver: SwiftUI.Color { .init(.silver) }

    /// The "TextFieldPrompt" asset catalog color.
    static var textFieldPrompt: SwiftUI.Color { .init(.textFieldPrompt) }

    /// The "defaultBackground" asset catalog color.
    static var defaultBackground: SwiftUI.Color { .init(.defaultBackground) }

    /// The "fontColor" asset catalog color.
    static var font: SwiftUI.Color { .init(.font) }

    /// The "headerColor" asset catalog color.
    static var header: SwiftUI.Color { .init(.header) }

    /// The "lightBlue" asset catalog color.
    static var lightBlue: SwiftUI.Color { .init(.lightBlue) }

    /// The "listColor" asset catalog color.
    static var list: SwiftUI.Color { .init(.list) }

    /// The "poolBlack" asset catalog color.
    static var poolBlack: SwiftUI.Color { .init(.poolBlack) }

    /// The "poolBlue" asset catalog color.
    static var poolBlue: SwiftUI.Color { .init(.poolBlue) }

    /// The "poolGray" asset catalog color.
    static var poolGray: SwiftUI.Color { .init(.poolGray) }

    /// The "poolGreen" asset catalog color.
    static var poolGreen: SwiftUI.Color { .init(.poolGreen) }

    /// The "poolRed" asset catalog color.
    static var poolRed: SwiftUI.Color { .init(.poolRed) }

    /// The "poolWhite" asset catalog color.
    static var poolWhite: SwiftUI.Color { .init(.poolWhite) }

    /// The "poolYellow" asset catalog color.
    static var poolYellow: SwiftUI.Color { .init(.poolYellow) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "DefaultPin" asset catalog image.
    static var defaultPin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .defaultPin)
#else
        .init()
#endif
    }

    /// The "EndPin" asset catalog image.
    static var endPin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .endPin)
#else
        .init()
#endif
    }

    /// The "StartPin" asset catalog image.
    static var startPin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .startPin)
#else
        .init()
#endif
    }

    /// The "grayback" asset catalog image.
    static var grayback: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .grayback)
#else
        .init()
#endif
    }

    /// The "pool" asset catalog image.
    static var pool: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pool)
#else
        .init()
#endif
    }

    /// The "pools" asset catalog image.
    static var pools: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pools)
#else
        .init()
#endif
    }

    /// The "zenitsu" asset catalog image.
    static var zenitsu: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .zenitsu)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "DefaultPin" asset catalog image.
    static var defaultPin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .defaultPin)
#else
        .init()
#endif
    }

    /// The "EndPin" asset catalog image.
    static var endPin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .endPin)
#else
        .init()
#endif
    }

    /// The "StartPin" asset catalog image.
    static var startPin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .startPin)
#else
        .init()
#endif
    }

    /// The "grayback" asset catalog image.
    static var grayback: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .grayback)
#else
        .init()
#endif
    }

    /// The "pool" asset catalog image.
    static var pool: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pool)
#else
        .init()
#endif
    }

    /// The "pools" asset catalog image.
    static var pools: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pools)
#else
        .init()
#endif
    }

    /// The "zenitsu" asset catalog image.
    static var zenitsu: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .zenitsu)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif