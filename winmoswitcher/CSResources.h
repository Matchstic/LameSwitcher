//
//  CSResources.h
//  
//
//  Created by Kyle Howells on 22/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SBApplication;

@interface CSResources : NSObject

// Images
+(UIImage*)currentAppImage;
+(void)setCurrentAppImage:(UIImage*)image;
+(void)reset;
+(BOOL)cachScreenShot:(UIImage*)screenshot forApp:(SBApplication*)app;
+(UIImage*)cachedScreenShot:(SBApplication*)app;
+(UIImage*)appScreenShot:(SBApplication*)app;
+(void)removeScreenshotForApp:(SBApplication *)app;
+(void)didReceiveMemoryWarning;

// Settings
+(BOOL)swipeCloses;
+(BOOL)showsCloseBox;
+(BOOL)showsAppTitle;
+(BOOL)showsAppIcon;
+(BOOL)showsPageControl;
+(BOOL)autoBackgroundApps;
+(int)cornerRadius;
+(int)tapsToLaunch;
+(int)backgroundStyle;
+(BOOL)goHomeOnHomeButton;
+(BOOL)showExitAllButton;
+(int)closeAnimation;
+(BOOL)excludeFromExiting:(SBApplication *)app;
+(float)transparency;
+(float)blurRadius;
+(BOOL)noRunOutStrife;

+(BOOL)customColourWasSet;
+(NSString *)customHexColour;
+(NSString *)preDefinedColour;

+(void)reloadSettings;

@end
