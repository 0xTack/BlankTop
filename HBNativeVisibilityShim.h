//
//  HBNativeVisibilityShim.h
//  BlankTop
//
//  Interface derived from Hidden Bar (https://github.com/dwarvesf/hidden),
//  Copyright © 2026 Dwarves Foundation, MIT License.
//
//  The only boundary to macOS 27's private MenuBarClientCore framework (the
//  menu-bar allow-list behind assessment mode). Objective-C so that exceptions
//  raised by a changed private API are caught instead of crashing the app.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Whether the framework, both classes and every selector used below resolve.
BOOL HBNativeVisibilityIsAvailable(void);

// Keeps only the given system items and apps visible; macOS hides every other
// status item and reflows the bar. The completion runs on the main queue with
// the assertion to hold (hiding lasts until it is invalidated or this process
// exits) or with an error.
void HBNativeVisibilityActivate(NSArray<NSNumber *> *allowedSystemItems,
                                NSArray<NSString *> *allowedBundleIdentifiers,
                                void (^completion)(id _Nullable assertion, NSError * _Nullable error));

void HBNativeVisibilityInvalidate(id assertion);

NS_ASSUME_NONNULL_END
