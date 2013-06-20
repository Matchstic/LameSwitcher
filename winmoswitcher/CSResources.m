//
//  CSResources.m
//  
//
//  Created by Kyle Howells on 22/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard/SpringBoard.h>
#import "CSApplicationController.h"
#import "CSResources.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>

CGImageRef UIGetScreenImage(void);

static NSDictionary *settings = nil;
static UIImage *currentImage = nil;

@interface SBApplication ()
- (BOOL)defaultStatusBarHidden;
- (int)statusBarStyle;
@end

@implementation CSResources


+(UIImage*)currentAppImage{
    NSLog(@"CSResources currentAppImage");
    return currentImage;
}
+(void)setCurrentAppImage:(UIImage*)image{
    NSLog(@"CSResources setCurrentAppImage");
    [currentImage release];
    currentImage = nil;
    currentImage = [image retain];
}


+(void)reset{
    NSLog(@"CSResources reset");
    [currentImage release];
    currentImage = nil;
}

+(void)didReceiveMemoryWarning{
    NSLog(@"CSResources didReceiveMemoryWarning");
}


+(BOOL)cachScreenShot:(UIImage*)screenshot forApp:(SBApplication*)app{
    NSLog(@"CSResources cachScreenShot:forApp");

    // Save snapshot to disk
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/User/Library/Caches/WinMoSwitcher" withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/WinMoSwitcher/%@", [app displayIdentifier]];
    //BOOL success = [UIImagePNGRepresentation(screenshot) writeToFile:pngPath atomically:YES];
    [UIImagePNGRepresentation(screenshot) writeToFile:pngPath atomically:YES];

    return YES;
}

+(UIImage*)cachedScreenShot:(SBApplication*)app{
    NSLog(@"CSResources cachedScreenShot:");
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    if (runningApp == nil) {
        runningApp = [(SBApplicationController *)[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.apple.springboard"];
    }
    if (currentImage && [[runningApp displayIdentifier] isEqualToString:[app displayIdentifier]]) {
        // Add the current image as the most up-to-date snapshot
        // Ensure there's no lag opening the switcher
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/User/Library/Caches/WinMoSwitcher"]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:@"/User/Library/Caches/WinMoSwitcher" withIntermediateDirectories:YES attributes:nil error:nil];
            }
                
            NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/WinMoSwitcher/%@", [app displayIdentifier]];
            [UIImagePNGRepresentation(currentImage) writeToFile:pngPath atomically:YES];
        });
            
        return currentImage;
    }

    // Load from saved snapshot
    NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/WinMoSwitcher/%@", [app displayIdentifier]];
    UIImage *img = [UIImage imageWithContentsOfFile:pngPath];
    if (img) return img;
    
    // Backup in the event there isn't a saved snapshot - get image from currently running app; will be useful for getting it for SpringBoard?
    return [self appScreenShot:app];
}

+(UIImage*)appScreenShot:(SBApplication*)app{
    NSLog(@"CSResources appScreenShot:");
    int originalOrientation = 0;
    int currentOrientation = 0;
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    if (!app)
        return nil;

    // If the app doesn't display the status bar (or a see through one) just return it's snapshot.
    if ([app defaultStatusBarHidden] || [app statusBarStyle] == UIStatusBarStyleBlackTranslucent) {
        UIImage *img = [app defaultImage:NULL preferredScale:scale originalOrientation:&originalOrientation currentOrientation:&currentOrientation];
        [self cachScreenShot:img forApp:app];
        return img;
    }

    // Else to avoid weirdness we need to render a fake status bar above the snapshot
    UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);

    [[UIColor blackColor] set];
    UIRectFill([UIScreen mainScreen].bounds);

    [[app defaultImage:NULL preferredScale:scale originalOrientation:&originalOrientation currentOrientation:&currentOrientation] drawInRect:CGRectMake(0, 20, SCREEN_WIDTH, SCREEN_HEIGHT-20)];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self cachScreenShot:img forApp:app];
    return img;
}

+(void)removeScreenshotForApp:(SBApplication *)app {
    NSError *error;
        
    NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/WinMoSwitcher/%@", [app displayIdentifier]];
    [[NSFileManager defaultManager] removeItemAtPath:pngPath error:&error];
}

#pragma mark Settings

+(BOOL)swipeCloses{
    return YES;
}
+(BOOL)showsCloseBox{
    return NO;
}
+(BOOL)showsAppTitle{
    id temp = [settings objectForKey:@"ShowAppTitle"];
	return (temp ? [temp boolValue] : YES);
}
+(BOOL)showsAppIcon {
    id temp = [settings objectForKey:@"showsAppIcon"];
    return (temp ? [temp boolValue] : NO);
}
+(BOOL)showsPageControl {
    id temp = [settings objectForKey:@"ShowPageDots"];
    return (temp ? [temp boolValue] : NO);
}
+(BOOL)autoBackgroundApps {
    id temp = [settings objectForKey:@"AutoBackground"];
    return (temp ? [temp boolValue] : NO);
}
+(int)cornerRadius {
    return 0;
}
+(int)tapsToLaunch {
    id temp = [settings objectForKey:@"TapsActivate"];
	return (temp ? [temp intValue] : 1);
}
+(int)backgroundStyle{
    id temp = [settings objectForKey:@"Background"];
	return (temp ? [temp intValue] : 1);
}
+(BOOL)goHomeOnHomeButton {
    id temp = [settings objectForKey:@"homeOnHome"];
    return (temp ? [temp boolValue] : YES);
}
+(BOOL)showExitAllButton {
    id temp = [settings objectForKey:@"showExitAllButton"];
    return (temp ? [temp boolValue] : NO);
}
+(int)closeAnimation {
    id temp = [settings objectForKey:@"deactivateAnimation"];
    return (temp ? [temp intValue] : 2);
}
+(BOOL)excludeFromExiting:(SBApplication *)app {
    BOOL exclude = [[settings objectForKey:[@"Exclude-" stringByAppendingString:[app displayIdentifier]]] boolValue];
    return exclude;
}
+(float)blurRadius {
    id temp = [settings objectForKey:@"blurriness"];
    return (temp ? [temp intValue] : 0.9);
}
+(float)transparency {
    id temp  = [settings objectForKey:@"transparency"];
    return (temp ? [temp floatValue] : 1.0f);
}
+(BOOL)noRunOutStrife {
    id temp = [settings objectForKey:@"noRunOutStrife"];
    return (temp ? [temp boolValue] : NO);
}

+(BOOL)alwaysShowHomeSnapshot {
    id temp = [settings objectForKey:@"alwaysShowHomeSnapshot"];
    return (temp ? [temp boolValue] : NO);
}

// Support for those without Strife
+(BOOL)customColourWasSet {
    id temp = [settings objectForKey:@"customColourWasSet"];
    return (temp ? [temp boolValue] : NO);
}
+(NSString *)customHexColour {
    id string = [settings objectForKey:@"customHexColour"];
    if (string != nil) {
        return string;
    } else {
        return @"1BA1E2";
    }
}
+(NSString *)preDefinedColour {
    id string = [settings objectForKey:@"preDefinedColour"];
    if (string != nil) {
        return string;
    } else {
        return @"1BA1E2";
    }
}

+(void)reloadSettings{
    [settings release];
    settings = nil;
    settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.matchstic.winmoswitcher.plist"];
}


@end
