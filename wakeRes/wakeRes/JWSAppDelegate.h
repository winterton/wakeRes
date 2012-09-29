//
//  JWSAppDelegate.h
//  wakeRes
//
//  Created by Jacob Smith on 9/28/12.
//  Copyright (c) 2012 Jacob Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JWSAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu* _menu;
    NSStatusItem* _statusItem;
    
    size_t _displayHeight;
    size_t _displayWidth;
    
    IBOutlet NSMenu* _wakeMenu;
    IBOutlet NSMenu* _delayMenu;
}

@property (assign) IBOutlet NSWindow *window;

@end
