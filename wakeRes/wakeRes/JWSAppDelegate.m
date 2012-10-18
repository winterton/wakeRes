//
//  JWSAppDelegate.m
//  wakeRes
//
//  Created by Jacob Smith on 9/28/12.
//  Copyright (c) 2012 Jacob Smith. All rights reserved.
//

#import "JWSAppDelegate.h"
#import <ApplicationServices/ApplicationServices.h>

@implementation JWSAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self registerForNotifications];
    [self setDefaults];
}

- (void)awakeFromNib {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_menu];
    [_statusItem setImage:[NSImage imageNamed:@"SidebarDisplay.png"]];
    [_statusItem setHighlightMode:YES];
    
    [self updateCurrentResolutionItem];
}

/*
 Use -(void)setImage:(NSImage*)image to set an image rather than status bar title
 
 */

- (IBAction)quitApp:(id)sender {
    [NSApp terminate:self];
}

#pragma mark -
#pragma mark Menu Methods

- (void)updateCurrentResolutionItem {
    NSMenuItem* item = [_menu itemAtIndex:0];
    
    CGDirectDisplayID displayID = CGMainDisplayID();
    
    _displayHeight = CGDisplayPixelsHigh(displayID);
    _displayWidth = CGDisplayPixelsWide(displayID);
    
    NSString *displayResolution = [NSString stringWithFormat:@"Resolution: %zu x %zu",_displayWidth,_displayHeight];
    
    [item setTitle:displayResolution];
    
    CGDisplayRelease(displayID);
    
}

- (IBAction)toggleRefreshOnWakeFunctionality:(id)sender {
    NSMenuItem* sendingMenuItem = (NSMenuItem*)sender;
    
    if ([[sendingMenuItem title] isEqualToString:@"Enable"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"refreshOnWakeEnabled"];
        
        [[_wakeMenu itemWithTitle:@"Disable"] setEnabled:YES];
        [[_wakeMenu itemWithTitle:@"Disable"] setState:0];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"refreshOnWakeEnabled"];
        
        [[_wakeMenu itemWithTitle:@"Enable"] setEnabled:YES];
        [[_wakeMenu itemWithTitle:@"Enable"] setState:0];
    }
    
    [sendingMenuItem setEnabled:NO];
    [sendingMenuItem setState:1];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (IBAction)setDelay:(id)sender {
    NSMenuItem* sendingItem = (NSMenuItem*)sender;
    
    [sendingItem setState:1];
    [[_delayMenu itemWithTag:[[NSUserDefaults standardUserDefaults] integerForKey:@"onWakeDelay"]] setState:0];
    
    [[NSUserDefaults standardUserDefaults] setInteger:sendingItem.tag forKey:@"onWakeDelay"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (IBAction)launchAbout:(id)sender {
    [self.window makeKeyAndOrderFront:self.window];
}

#pragma mark -
#pragma mark Resolution Management Methods

// TODO: See inline comment.

- (IBAction)refreshResolution:(id)sender {
    CGDirectDisplayID displayID = CGMainDisplayID();
    
    CFArrayRef displayModeArray = CGDisplayCopyAllDisplayModes(displayID, nil);
    CGDisplayModeRef currentDisplayMode = CGDisplayCopyDisplayMode(displayID);
    
    CFIndex initialDisplayModeIndex = CFArrayGetFirstIndexOfValue(displayModeArray, CFRangeMake(0, CFArrayGetCount(displayModeArray)), currentDisplayMode);

    //This could break if released to public, specifically in the case where a user has a limited number of
    //display modes, so do this the right way before giving out any download links.
    CGDisplayModeRef targetDisplayModeRef = (CGDisplayModeRef)CFArrayGetValueAtIndex(displayModeArray, 0);

    [self switchResolutionWithDisplayMode:targetDisplayModeRef];
    
    targetDisplayModeRef = (CGDisplayModeRef)CFArrayGetValueAtIndex(displayModeArray, initialDisplayModeIndex);
    
    [self switchResolutionWithDisplayMode:targetDisplayModeRef];
    
    
    CFRelease(displayModeArray);
    CGDisplayModeRelease(targetDisplayModeRef);
    CGDisplayModeRelease(currentDisplayMode);
    CGDisplayRelease(displayID);
}

- (void)switchResolutionWithDisplayMode:(CGDisplayModeRef)displayMode {
    CGDirectDisplayID displayID = CGMainDisplayID();
    
    CGDisplayConfigRef configRef;
    
    CGBeginDisplayConfiguration(&configRef);
    
    CGConfigureDisplayWithDisplayMode(configRef, displayID, displayMode, nil);
    
    CGCompleteDisplayConfiguration(configRef, kCGConfigureForSession);
    
    [self updateCurrentResolutionItem];
    
    CGDisplayRelease(displayID);
}

#pragma mark -
#pragma mark Sleep/Wake Notifications

- (void) receiveWorkSpaceNotifications: (NSNotification*) note
{
    if ([note.name isEqualToString:NSWorkspaceDidWakeNotification]){
        //refresh the resolution if user defaults shows wake enabled
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshOnWakeEnabled"]) {
            NSInteger delay = [[NSUserDefaults standardUserDefaults] integerForKey:@"onWakeDelay"];
            [self performSelector:@selector(refreshResolution:) withObject:nil afterDelay:delay];
        }
    }
    else if ([note.name isEqualToString:NSWorkspaceDidActivateApplicationNotification]) {
        NSRunningApplication* application = [note.userInfo objectForKey:NSWorkspaceApplicationKey];
        NSLog(@"%@ is activated",application);
        if ([application.bundleIdentifier isEqualToString:@"com.apple.finder"]) {
            NSLog(@"setting default presentation");
            [self setDockAutoHide];
        }
    }
    else if ([note.name isEqualToString:NSWorkspaceDidDeactivateApplicationNotification]) {
        NSRunningApplication* application = [note.userInfo objectForKey:NSWorkspaceApplicationKey];
        NSLog(@"%@ is deactiveated",application);
        if(![application.bundleIdentifier isEqualToString:@"me.winterton.wakeRes"]){
            NSLog(@"setting autohide");
            [self setDockAutoHide];
        }
    }
    else {
        NSLog(@"Notification: %@",note.name);
    }
    
}


//Use HID event tap and run program as root?
- (void) setDockAutoHide {
    CGEventRef event1, event2, event3;
    NSLog(@"authide command");
    event1 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)55, true);
    event2 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)58, true);
    event3 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)4, true);
    
    CGEventPost(kCGSessionEventTap, event1);
    CGEventPost(kCGSessionEventTap, event2);
    CGEventPost(kCGSessionEventTap, event3);
    
    event1 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)55, false);
    event2 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)58, false);
    event3 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)4, false);
    
    
    CGEventPost(kCGSessionEventTap, event1);
    CGEventPost(kCGSessionEventTap, event2);
    CGEventPost(kCGSessionEventTap, event3);
    
    CFRelease(event1);
    CFRelease(event2);
    CFRelease(event3);
}

- (void) registerForNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWorkSpaceNotifications:)
                                                               name: NULL object: NULL];
    
    
}

#pragma mark - 
#pragma mark Misc Methods

- (void) setDefaults {
    [[NSUserDefaults standardUserDefaults] setInteger:15 forKey:@"onWakeDelay"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"refreshOnWakeEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 
#pragma mark About Window Methods

- (IBAction)launchHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/winterton/wakeRes/blob/master/README.md"]];
}

@end
