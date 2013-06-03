//
//  winmoswitcher_prefsController.m
//  winmoswitcher-prefs
//
//  Created by Matt Clarke on 25/05/2013.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "winmoswitcher_prefsController.h"
#import <Preferences/PSSpecifier.h>

static NSString *settingsFile = @"/var/mobile/Library/Preferences/com.matchstic.winmoswitcher.plist";

@implementation winmoswitcher_prefsController

-(id)specifiers {
    if (_specifiers == nil) {
		NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"WinMoSwitcher" target:self];
        
        NSFileManager *file = [NSFileManager defaultManager];
        // If Strife isn't there, remove the Strife options
        if (![file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"]) {
            // Hide Strife options
            [testingSpecs removeObjectAtIndex:10];
            [testingSpecs removeObjectAtIndex:9];
        }
        
        _specifiers = [testingSpecs retain];
    }
    
	return _specifiers;
}

-(id)init {
	if ((self = [super init])) {
	}
	
	return self;
}

-(void)dealloc {
	[super dealloc];
}

-(void)viewDidAppear:(BOOL)view {
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.1];
}

-(NSString *)getBackgroundValue {
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
    int style = [[dict objectForKey:@"Background"] intValue];
    NSString *stringStyle = nil;
    if (style == 1) {
        NSFileManager *file = [NSFileManager defaultManager];
        if ([file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"]) {
            stringStyle = @"Tile colour";
        } else {
            stringStyle = @"Custom colour";
        }
    } else if (style == 2) {
        stringStyle = @"Dark";
    } else if (style == 3) {
        stringStyle = @"Light";
    } else {
        // Need a fallback for when it's just been installed
        NSFileManager *file = [NSFileManager defaultManager];
        if ([file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"]) {
            stringStyle = @"Tile colour";
        } else {
            stringStyle = @"Custom colour";
        }
    }
    [dict release];
    return stringStyle;
}

@end

@implementation backgroundController

-(id)specifiers {
    if (_specifiers == nil) {
		NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Background" target:self];
    
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
        if (![[dict objectForKey:@"customColourWasSet"] boolValue]) {
            [testingSpecs removeObjectAtIndex:8];
        }
        
        NSFileManager *file = [NSFileManager defaultManager];
        // If Strife is there, show the Strife options.
        if ([file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"]) {
            // Custom colour style options
            [testingSpecs removeObjectAtIndex:7];
            [testingSpecs removeObjectAtIndex:6];
            [testingSpecs removeObjectAtIndex:5];
            // Hide non-Strife options
            [testingSpecs removeObjectAtIndex:1];
        } else {
            // Hide Strife-only options
            [testingSpecs removeObjectAtIndex:0];
        }
    
        _specifiers = [testingSpecs retain];
    }
    
	return _specifiers;
}

-(void)enableCustomColour:(id)value forSpecifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    
    NSArray *specs = [self loadSpecifiersFromPlistName:@"Background" target:self];
    if (value == kCFBooleanTrue) {
        [self insertSpecifier:[specs objectAtIndex:8] atIndex:8 animated:YES];
    } else {
        [self removeSpecifier:[_specifiers objectAtIndex:8] animated:YES];
    }
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.matchstic.winmoswitcher/settingschanged"), NULL, NULL, TRUE);
    
}
/*-(void)setPreDefinedColour:(id)value forSpecifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsFile];
    [dict setValue:NO forKey:@"customColourWasSet"];
    [dict writeToFile:settingsFile atomically:YES];
    [dict release];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.matchstic.winmoswitcher/settingschanged"), NULL, NULL, TRUE);
}*/

@end