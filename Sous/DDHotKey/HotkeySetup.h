//
//  HotkeySetup.h
//  Sous
//
//  Created by nate parrott on 10/12/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HotkeySetup : NSObject

+(void)registerGlobalHotkey:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
