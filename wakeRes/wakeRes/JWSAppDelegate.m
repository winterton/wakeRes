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

- (void) receiveWakeNote: (NSNotification*) note
{
    NSLog(@"receiveSleepNote: %@", [note name]);
    
    //refresh the resolution if user defaults shows wake enabled
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"refreshOnWakeEnabled"]) {
        NSInteger delay = [[NSUserDefaults standardUserDefaults] integerForKey:@"onWakeDelay"];
        [self performSelector:@selector(refreshResolution:) withObject:nil afterDelay:delay];
    }
    
}

- (void) registerForNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
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
