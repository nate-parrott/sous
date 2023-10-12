//
//  HotkeySetup.m
//  Sous
//
//  Created by nate parrott on 10/12/23.
//

#import "HotkeySetup.h"
#import "DDHotKeyCenter.h"
@import Carbon;
@import AppKit;

@implementation HotkeySetup

+(void)registerGlobalHotkey:(void (^)(void))block {
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKeyWithKeyCode:kVK_Space modifierFlags:NSEventModifierFlagOption task:^(NSEvent *event) {
        block();
    }];
}

@end
