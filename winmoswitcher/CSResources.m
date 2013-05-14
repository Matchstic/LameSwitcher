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

CGImageRef UIGetScreenImage(void);

static NSMutableDictionary *cache = nil;
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
    [cache removeAllObjects];
    [currentImage release];
    currentImage = nil;
}

+(void)didReceiveMemoryWarning{
    NSLog(@"CSResources didReceiveMemoryWarning");
    [cache removeAllObjects];
    [cache release];
    cache = nil;
}


+(BOOL)cachScreenShot:(UIImage*)screenshot forApp:(SBApplication*)app{
    NSLog(@"CSResources cacheScreenShot:forApp");
    if (!cache)
        cache = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Caches/WinMoSwitcher/cache.plist"];
    if (!cache)
        cache = [[NSMutableDictionary alloc] init];

    [screenshot retain];

    [[NSFileManager defaultManager] createDirectoryAtPath:@"/User/Library/Caches/WinMoSwitcher" withIntermediateDirectories:YES attributes:nil error:nil];
    //NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/CardSwitcher/%@", [app displayIdentifier]];
    //BOOL success = [UIImagePNGRepresentation(screenshot) writeToFile:pngPath atomically:YES];

    //if (success)
        [cache setObject:screenshot forKey:[app displayIdentifier]];
        [cache writeToFile:@"/User/Library/Caches/WinMoSwitcher/cache.plist" atomically:YES];

    [screenshot release];

    return YES;
}

+(UIImage*)cachedScreenShot:(SBApplication*)app{
    NSLog(@"CSResources cachedScreenShot");
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    if (currentImage && [[runningApp displayIdentifier] isEqualToString:[app displayIdentifier]]) {
        return currentImage;
    }

    if (!cache)
        cache = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Caches/WinMoSwitcher/cache.plist"];
    if (!cache)
        cache = [[NSMutableDictionary alloc] init];
    if (cache) {
        if ([cache objectForKey:[app displayIdentifier]])
            return [cache objectForKey:[app displayIdentifier]];
    }

    /*NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/CardSwitcher/%@", [app displayIdentifier]];
    UIImage *img = [UIImage imageWithContentsOfFile:pngPath];
    if (img) return img;*/

    return [self appScreenShot:app];
}

+(UIImage*)appScreenShot:(SBApplication*)app{
    NSLog(@"CSResources appScreenShot");
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

    if ([app statusBarStyle] == UIStatusBarStyleBlackOpaque) {
        [[UIColor blackColor] set];
        UIRectFill([UIScreen mainScreen].bounds);
    }
    else {
        [[CSApplicationController sharedController].statusBarDefault drawInRect:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
    }

    [[app defaultImage:NULL preferredScale:scale originalOrientation:&originalOrientation currentOrientation:&currentOrientation] drawInRect:CGRectMake(0, 20, SCREEN_WIDTH, SCREEN_HEIGHT-20)];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self cachScreenShot:img forApp:app];
    return img;
}



#pragma mark Settings

+(BOOL)swipeCloses{
    NSLog(@"CSResources swipeCloses");
    //id temp = [settings objectForKey:@"CSSwipeClose"];
	//return (temp ? [temp boolValue] : YES);
    return YES;
}
+(BOOL)showsCloseBox{
    NSLog(@"CSResources showsCloseBox");
    //id temp = [settings objectForKey:@"CSShowCloseButtons"];
	//return (temp ? [temp boolValue] : YES);
    return NO;
}
+(BOOL)showsAppTitle{
    NSLog(@"CSResources showsAppTitle");
    id temp = [settings objectForKey:@"ShowAppTitle"];
	return (temp ? [temp boolValue] : YES);
}
+(BOOL)showsPageControl{
    NSLog(@"CSResources showsPageControl");
    id temp = [settings objectForKey:@"ShowPageDots"];
    return (temp ? [temp boolValue] : YES);
}
+(BOOL)autoBackgroundApps{
    NSLog(@"CSResources autoBackgroundApps");
    id temp = [settings objectForKey:@"AutoBackground"];
    return (temp ? [temp boolValue] : NO);
}
+(int)cornerRadius{
    NSLog(@"CSResources cornerRadius");
    //id temp = [settings objectForKey:@"CornerRadius"];
	//return (temp ? [temp intValue] : 10);
    return 0;
}
+(int)tapsToLaunch{
    NSLog(@"CSResources tapsToLaunch");
    id temp = [settings objectForKey:@"TapsActivate"];
	return (temp ? [temp intValue] : 1);
}
+(int)backgroundStyle{
    NSLog(@"CSResources backgroundStyle");
    id temp = [settings objectForKey:@"Background"];
	return (temp ? [temp intValue] : 1);
}

+(void)reloadSettings{
    NSLog(@"CSResources reloadSettings");
    [settings release];
    settings = nil;
    settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.matchstic.winmoswitcher.plist"];
}


@end
