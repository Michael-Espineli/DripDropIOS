#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"Espineli-LLC.DripDrop";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "Bronze" asset catalog color resource.
static NSString * const ACColorNameBronze AC_SWIFT_PRIVATE = @"Bronze";

/// The "DarkGray" asset catalog color resource.
static NSString * const ACColorNameDarkGray AC_SWIFT_PRIVATE = @"DarkGray";

/// The "Gold" asset catalog color resource.
static NSString * const ACColorNameGold AC_SWIFT_PRIVATE = @"Gold";

/// The "Other" asset catalog color resource.
static NSString * const ACColorNameOther AC_SWIFT_PRIVATE = @"Other";

/// The "RealYellow" asset catalog color resource.
static NSString * const ACColorNameRealYellow AC_SWIFT_PRIVATE = @"RealYellow";

/// The "Silver" asset catalog color resource.
static NSString * const ACColorNameSilver AC_SWIFT_PRIVATE = @"Silver";

/// The "TextFieldPrompt" asset catalog color resource.
static NSString * const ACColorNameTextFieldPrompt AC_SWIFT_PRIVATE = @"TextFieldPrompt";

/// The "defaultBackground" asset catalog color resource.
static NSString * const ACColorNameDefaultBackground AC_SWIFT_PRIVATE = @"defaultBackground";

/// The "fontColor" asset catalog color resource.
static NSString * const ACColorNameFontColor AC_SWIFT_PRIVATE = @"fontColor";

/// The "headerColor" asset catalog color resource.
static NSString * const ACColorNameHeaderColor AC_SWIFT_PRIVATE = @"headerColor";

/// The "lightBlue" asset catalog color resource.
static NSString * const ACColorNameLightBlue AC_SWIFT_PRIVATE = @"lightBlue";

/// The "listColor" asset catalog color resource.
static NSString * const ACColorNameListColor AC_SWIFT_PRIVATE = @"listColor";

/// The "poolBlack" asset catalog color resource.
static NSString * const ACColorNamePoolBlack AC_SWIFT_PRIVATE = @"poolBlack";

/// The "poolBlue" asset catalog color resource.
static NSString * const ACColorNamePoolBlue AC_SWIFT_PRIVATE = @"poolBlue";

/// The "poolGray" asset catalog color resource.
static NSString * const ACColorNamePoolGray AC_SWIFT_PRIVATE = @"poolGray";

/// The "poolGreen" asset catalog color resource.
static NSString * const ACColorNamePoolGreen AC_SWIFT_PRIVATE = @"poolGreen";

/// The "poolRed" asset catalog color resource.
static NSString * const ACColorNamePoolRed AC_SWIFT_PRIVATE = @"poolRed";

/// The "poolWhite" asset catalog color resource.
static NSString * const ACColorNamePoolWhite AC_SWIFT_PRIVATE = @"poolWhite";

/// The "poolYellow" asset catalog color resource.
static NSString * const ACColorNamePoolYellow AC_SWIFT_PRIVATE = @"poolYellow";

/// The "DefaultPin" asset catalog image resource.
static NSString * const ACImageNameDefaultPin AC_SWIFT_PRIVATE = @"DefaultPin";

/// The "EndPin" asset catalog image resource.
static NSString * const ACImageNameEndPin AC_SWIFT_PRIVATE = @"EndPin";

/// The "StartPin" asset catalog image resource.
static NSString * const ACImageNameStartPin AC_SWIFT_PRIVATE = @"StartPin";

/// The "grayback" asset catalog image resource.
static NSString * const ACImageNameGrayback AC_SWIFT_PRIVATE = @"grayback";

/// The "pool" asset catalog image resource.
static NSString * const ACImageNamePool AC_SWIFT_PRIVATE = @"pool";

/// The "pools" asset catalog image resource.
static NSString * const ACImageNamePools AC_SWIFT_PRIVATE = @"pools";

/// The "zenitsu" asset catalog image resource.
static NSString * const ACImageNameZenitsu AC_SWIFT_PRIVATE = @"zenitsu";

#undef AC_SWIFT_PRIVATE
