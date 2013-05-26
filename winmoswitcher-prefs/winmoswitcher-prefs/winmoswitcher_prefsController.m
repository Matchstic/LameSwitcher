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
	if (_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"WinMoSwitcher" target:self] retain];
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
    }
    [dict release];
    return stringStyle;
}

@end

@implementation backgroundController

-(id)specifiers {
    if (_specifiers == nil) {
		NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Background" target:self];
    
        NSFileManager *file = [NSFileManager defaultManager];
        // If Strife is there, show the Strife options.
        if ([file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"]) {
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

/*-(void)viewWillAppear:(BOOL)view {
    NSFileManager *file = [NSFileManager defaultManager];
    [self reloadSpecifiers];
    // If Strife is there, show the Strife options.
    if ([file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"] && !backgroundViewhasLoaded) {
        // Hide non-Strife options
        [self removeSpecifier:[_specifiers objectAtIndex:2] animated:NO];
        backgroundViewhasLoaded = YES;
    } else if (!backgroundViewhasLoaded) {
        // Hide Strife-only options
        [self removeSpecifier:[_specifiers objectAtIndex:1] animated:NO];
        backgroundViewhasLoaded = YES;
    }
}
-(void)viewDidUnload {
    backgroundViewhasLoaded = NO;
}*/

-(void)setBackgroundValue:(id)value forSpecifier:(id)specifier {
    NSLog(@"Setting background value");
    NSLog(@"With value %@", value);
    NSLog(@"For specifier %@", specifier);
    
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
    [dict setValue:value forKey:@"Background"];
    [dict release];
}
-(int)getBackgroundValue {
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
    int value = [dict objectForKey:@"Background"];
    [dict release];
    return value;
}

@end