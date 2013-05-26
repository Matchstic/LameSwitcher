//
//  CSApplicationController.m
//  
//
//  Created by Kyle Howells on 21/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard/SpringBoard.h>
#import <SpringBoardUI/SpringBoardUI.h>
#import <QuartzCore/QuartzCore.h>
#import <IOSurface/IOSurface3.h>
#import "CSApplicationController.h"
#import "CSApplication.h"
#import "CSResources.h"

#define STRIFE_PREFS @"/var/mobile/Library/DreamBoard/Strife/Info.plist"
#define BUNDLE @"/Library/Application Support/WinMoSwitcher/WinMoSwitcher.bundle"

CGImageRef UIGetScreenImage(void);

@interface SBAwayController ()
+(id)sharedAwayController;
-(BOOL)isLocked;
@end

@interface SBWallpaperView ()
-(UIImage*)uncomposedImage;
@end

@interface SpringBoard (Backgrounder)
- (void)setBackgroundingEnabled:(BOOL)backgroundingEnabled forDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface UIImage (IOSurface)
- (id)_initWithIOSurface:(IOSurfaceRef)surface scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
@end

@interface UIWindow (IOSurface)
+(IOSurfaceRef)createScreenIOSurface;
@end

static CSApplicationController *_instance;
static SBApplication *openedOverApp;

@implementation CSApplicationController
@synthesize springBoardImage = _springBoardImage;
@synthesize ignoreRelaunchID = _ignoreRelaunchID;
@synthesize statusBarDefault = _statusBarDefault;
@synthesize displayStacks = _displayStacks;
@synthesize shouldAnimate = _shouldAnimate;
@synthesize isAnimating = _isAnimating;
@synthesize springBoard = _springBoard;
@synthesize runningApps = _runningApps;
@synthesize ignoredApps = _ignoredApps;
@synthesize ignoredIDs = _ignoredIDs;
@synthesize scrollView = _scrollView;
@synthesize closeBox = _closeBox;
@synthesize isActive = _isActive;

@synthesize pressedHome = _pressedHome;
@synthesize applaunching = _applaunching;
@synthesize exitingAllApps = _exitingAllApps;
@synthesize isLocking = _isLocking;

@synthesize transparentImage;
@synthesize backgroundView;
@synthesize exitBar;

+(CSApplicationController*)sharedController{
    if (!_instance) {
        _instance = [[CSApplicationController alloc] init];
    }

    return _instance;
}

- (id)init {
    NSLog(@"CSApplicationController init");
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {
        // Initialization code here.
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        self.closeBox = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CardSwitcher/closebox.png"];
        self.statusBarDefault = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CardSwitcher/UIStatusBarStyleDefault.png"];
        self.backgroundColor = [UIColor blackColor];
        self.windowLevel = UIWindowLevelStatusBar*42;
        self.shouldAnimate = NO;
        self.isAnimating = NO;
        self.isActive = NO;
        self.hidden = YES;
        self.displayStacks = [[[NSMutableArray alloc] init] autorelease];
        self.runningApps = [[[NSMutableArray alloc] init] autorelease];
        self.ignoredApps = [[[NSMutableArray alloc] init] autorelease];
        
        // *********************** Add any ignored apps to this 'ere array! *****************
        self.ignoredIDs = [NSMutableArray arrayWithObjects:@"com.wynd.dreamboard", nil];
        
        // ******************************************************* originx        originy                   width        height
        pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, (SCREEN_HEIGHT*0.97), self.frame.size.width, 20)];
        pageControl.userInteractionEnabled = NO;
        pageControl.numberOfPages = 1;
        pageControl.currentPage = 1;
        [self addSubview:pageControl];

        int edgeInset = 40;
        CGRect scrollViewFrame = self.bounds;
        scrollViewFrame.size.width = (self.bounds.size.width-(edgeInset*2));
        scrollViewFrame.origin.x = edgeInset;
        self.scrollView = [[[CSScrollView alloc] initWithFrame:scrollViewFrame] autorelease];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.alwaysBounceHorizontal = YES;
        self.scrollView.pagingEnabled = YES;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.scrollsToTop = NO;
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];

        //noAppsLabel = nil;
        //backgroundView = nil;
        [CSResources reloadSettings];

        //UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomOut:)] autorelease];
        //[self addGestureRecognizer:pinch];

        /*CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor colorWithRed:0.171 green:0.171 blue:0.171 alpha:1.000] CGColor], nil];
        [self.layer insertSublayer:gradient atIndex:0];*/

        currentOrientation = UIInterfaceOrientationPortrait;

        [pool release];
    }

    return self;
}

-(void)setHidden:(BOOL)_hidden{
    NSLog(@"CSApplicationController setHidden");
    self.userInteractionEnabled = !_hidden;
    [super setHidden:_hidden];
}


-(void)setRotation:(UIInterfaceOrientation)orientation{
    NSLog(@"CSApplicationController setRotation");
/*    if (currentOrientation == orientation) return;

    if (orientation == UIInterfaceOrientationPortrait) {
        self.transform = CGAffineTransformRotate(self.transform,0.0);
    }
    else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        self.transform = CGAffineTransformRotate(self.transform, 3.1415927);
    }*/
}

-(void)relayoutSubviews{
    NSLog(@"CSApplicationController relayoutSubviews");
    //Defaults
    pageControl.hidden = ![CSResources showsPageControl];

    self.backgroundColor = [UIColor clearColor];
    
    // Change background as appropriate
    //backgroundView = nil;
    [backgroundView removeFromSuperview];
    backgroundView = nil;
    if ([CSResources backgroundStyle] == 1) {
        // Look's like the user wants the background to be the same as the tile colour/a custom colour.
        // First, check if Strife is installed
        backgroundView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
        
        NSFileManager *file = [NSFileManager defaultManager];
        NSString *tileColour;
        
        // If Strife is there, use the tile colour - which is what's shown in Settings anyway.
        if ([file fileExistsAtPath:@"/DreamBoard/Strife/Info.plist"]) {
            // Get RBG from hex value, and add into an image
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/DreamBoard/Strife/Info.plist"];
            tileColour = [dict objectForKey:@"AccentColorHex"];
            [dict release];
        } else {
            // Give them a cyan colour for now
            tileColour = @"1BA1E2";
        }
        
        CGRect rect = [[UIScreen mainScreen] bounds];
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
            
        CGContextSetFillColorWithColor(context, [[self colorWithHexString:tileColour] CGColor]);
        CGContextFillRect(context, rect);
            
        UIImage *tile = UIGraphicsGetImageFromCurrentImageContext();
        backgroundView.image = tile;
        // Why is this being given a tag?!
        backgroundView.tag = 5;
        UIGraphicsEndImageContext();

        [self insertSubview:backgroundView atIndex:0];
    } else if ([CSResources backgroundStyle] == 2) {
        
        // Dark background
        
        backgroundView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
        CGRect rect = [[UIScreen mainScreen] bounds];
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context,  [[UIColor blackColor] CGColor]);
        CGContextFillRect(context, rect);
        UIImage *tile = UIGraphicsGetImageFromCurrentImageContext();
        backgroundView.image = tile;
        UIGraphicsEndImageContext();
        [self insertSubview:backgroundView atIndex:0];
        
    } else if ([CSResources backgroundStyle] == 3) {
        
        // Light background - remember to adjust text colour accordingly
        
        backgroundView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
        CGRect rect = [[UIScreen mainScreen] bounds];
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context,  [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, rect);
        UIImage *tile = UIGraphicsGetImageFromCurrentImageContext();
        backgroundView.image = tile;
        UIGraphicsEndImageContext();
        [self insertSubview:backgroundView atIndex:0];
        
    } else if ([CSResources backgroundStyle] == 4) {
        
        // Blurred lockscreen image - this doesn't work yet
        
        // Get lockscreen image
        SBWallpaperImage *image = [[SBWallpaperImage alloc] initWithVariant:0];
        UIImage *wallpaper = [UIImage imageWithData:image.data];
        
        // Blur the UIImage
        /*CIImage *imageToBlur = [CIImage imageWithCGImage:loadImage.CGImage];
        CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [gaussianBlurFilter setValue:imageToBlur forKey:@"inputImage"];
        [gaussianBlurFilter setValue:[NSNumber numberWithFloat:2] forKey:@"inputRadius"];
        CIImage *resultImage = [gaussianBlurFilter valueForKey:@"outputImage"];
        UIImage *endImage = [[UIImage alloc] initWithCIImage:resultImage];*/
        
        backgroundView.image = wallpaper;
        [self insertSubview:backgroundView atIndex:0];
        //[wallpaper release];
        [image release];
    } else if ([CSResources backgroundStyle] == 5) {
        
        // Transparent background - no settings support
        
        backgroundView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
        
        // Check if user wants blur
        //if ([CSResources blurForTransparent]) {
        // Blur the UIImage
        CIImage *imageToBlur = [CIImage imageWithCGImage:transparentImage.CGImage];
        CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [gaussianBlurFilter setValue:imageToBlur forKey:@"inputImage"];
        [gaussianBlurFilter setValue:[NSNumber numberWithFloat:5] forKey:@"inputRadius"];
        CIImage *resultImage = [gaussianBlurFilter valueForKey:@"outputImage"];
        UIImage *endImage = [[UIImage alloc] initWithCIImage:resultImage];
        
        backgroundView.image = endImage;
        backgroundView.alpha = 1.0f;
        
        [transparentImage release];
        transparentImage = nil;
        [endImage release];
    
        [self insertSubview:backgroundView atIndex:0];
    }
    
    //noAppsLabel = nil;
    [noAppsLabel removeFromSuperview];
    noAppsLabel = nil;

    if ([self.runningApps count] == 0) {
        noAppsLabel = [[[UILabel alloc] initWithFrame:self.frame] autorelease];
        noAppsLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        noAppsLabel.font = [UIFont boldSystemFontOfSize:17];
        noAppsLabel.textAlignment = NSTextAlignmentCenter;
        if ([CSResources backgroundStyle] == 3) {
            noAppsLabel.textColor = [UIColor blackColor];
        } else {
            noAppsLabel.textColor = [UIColor whiteColor];
        }
        noAppsLabel.text = @"No Apps Running";
        [self addSubview:noAppsLabel];
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    }
    
    // Time view code
    [timeLabel removeFromSuperview];
    timeLabel = nil;

    timeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, (SCREEN_WIDTH - 5), 24)] autorelease];
    timeLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    timeLabel.font = [UIFont systemFontOfSize:13];
    timeLabel.textAlignment = NSTextAlignmentRight;
    if ([CSResources backgroundStyle] == 3) {
        timeLabel.textColor = [UIColor blackColor];
    } else {
        timeLabel.textColor = [UIColor whiteColor];
    }
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"hh:mm"];
    NSString *dateString = [dateFormat stringFromDate:today];
    timeLabel.text = dateString;
    [dateFormat release];
    
    [self addSubview:timeLabel];
    [self runTimer];

    // Exit all apps button
    [exitButton removeFromSuperview];
    exitButton = nil;
    
    /*[exitBar removeFromSuperview];
    exitBar = nil;*/
    
    //Get the Bundle
    NSBundle *bundle = [[NSBundle alloc] initWithPath:BUNDLE];
    
    // Exit button images
    UIImage *close = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"Close" ofType:@"png"]];
    UIImage *darkClose = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"DarkClose" ofType:@"png"]];
    UIImage *closePressed = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"ClosePressed" ofType:@"png"]];
    
    if (([self.runningApps count] > 0) && [CSResources showExitAllButton]) {
        exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [exitButton addTarget:[CSApplication sharedController]
                       action:@selector(exitAllApps)
                    forControlEvents:UIControlEventTouchUpInside];
        if (!([CSResources backgroundStyle] == 3)) {
            [exitButton setImage:close forState:UIControlStateNormal];
        } else {
            [exitButton setImage:darkClose forState:UIControlStateNormal];
        }
        
        [exitButton setImage:closePressed forState:UIControlStateHighlighted];
        [exitButton setImage:closePressed forState:UIControlStateSelected];
        
        /*exitButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        exitButton.titleLabel.font = [UIFont systemFontOfSize:15];
        exitButton.titleLabel.textColor = [UIColor whiteColor];*/
        // ***********                            originx                           originy         width height
        exitButton.frame = CGRectMake((SCREEN_WIDTH/2)-(close.size.width/2), (SCREEN_HEIGHT*0.91), 30.0, 30.0);
        [self addSubview:exitButton];
        
        // Background bar for it
        /*CGRect barFrame = CGRectMake(0, (SCREEN_HEIGHT*0.8), SCREEN_WIDTH, (close.size.height*1.5));
        exitBar = [[[UIImageView alloc] initWithFrame:barFrame] autorelease];
        CGRect rect = barFrame;
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context,  [[UIColor grayColor] CGColor]);
        CGContextFillRect(context, rect);
        UIImage *bar = UIGraphicsGetImageFromCurrentImageContext();
        exitBar.image = bar;
        UIGraphicsEndImageContext();
        
        [self addSubview:exitBar];*/
    }

    CGSize screenSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width * [self.runningApps count], screenSize.height);

    static int i; // Work around for using "for (* in *)" rather then "for (int i = 0; i < array.count; i++)"
    i = 0;
    for (SBApplication *app in self.runningApps) {
        CSApplication *csApp = [[[CSApplication alloc] initWithApplication:app] autorelease];
        CGRect appRect = csApp.frame;
        appRect.origin.x = (i * screenSize.width) + ((screenSize.width-appRect.size.width)*0.5);
        csApp.frame = appRect;
        csApp.tag = (i + 1000);
        [csApp reset];
        [self.scrollView addSubview:csApp];

        i++;
    }
    [bundle release];
}


-(CSApplication*)csAppforApplication:(SBApplication*)app{
    NSLog(@"CSApplicationController csAppForApplication");
    for (CSApplication *csApplication in self.scrollView.subviews) {
        if ([app.displayIdentifier isEqualToString:csApplication.application.displayIdentifier]) {
            return csApplication;
        }
    }

    return nil;
}


-(void)appLaunched:(SBApplication*)app{
    NSLog(@"CSApplicationController appLaunched");
    for (NSString *string in self.ignoredIDs) {
        if ([[app displayIdentifier] isEqualToString:string]){
            if (![self.ignoredApps containsObject:app]) {
                [self.ignoredApps addObject:app];
            }
            return;
        }
    }

    if (![self.runningApps containsObject:app]) {
        [self.runningApps addObject:app];
    }
}

-(void)appQuit:(SBApplication*)app{
    NSLog(@"CSApplicationController appQuit");
    if ([self.ignoredApps containsObject:app]) {
        [self.ignoredApps removeObject:app];
        return;
    }
    if (![self.runningApps containsObject:app]) { return; }


    if (self.isActive) {
        // Remove from the screen
        CSApplication *appView = [self csAppforApplication:app];
        [appView removeFromSuperview];

        // And remove it from the array
        [self.runningApps removeObject:app];
        
        // Remove its cached screenshot from disk
        [CSResources removeScreenshotForApp:app];

        // Animate the ScrollView smaller
        [UIView animateWithDuration:0.2 animations:^{
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.runningApps.count, 0);
        } completion:^(BOOL finished){}];
        [self checkPages];

        // Animate the apps closer together
        CGSize screenSize = self.scrollView.frame.size;
        
        static int i; // Work around for using "for (* in *)" rather then "for (int i = 0; i < array.count; i++)"
        i = 0;
        for (CSApplication *psApp in self.scrollView.subviews) {
            psApp.tag = (1000+i);

            CGRect appRect = psApp.frame;
            appRect.origin.x = (i * screenSize.width) + ((screenSize.width-appRect.size.width)*0.5);
            [UIView animateWithDuration:0.2 animations:^{
                psApp.frame = appRect;
            } completion:^(BOOL finished){}];

            i++;
        }

        if (self.runningApps.count == 0) {
            self.pressedHome = YES;
            [self setActive:NO];
        }

        return;
    }

    [self.runningApps removeObject:app];
}


-(void)deactivateGesture:(UIGestureRecognizer*)gesture{
    NSLog(@"CSApplicationController deactiveGesture");
    if (gesture.state != UIGestureRecognizerStateEnded)
        return;

    [self setActive:NO];
}

-(void)runTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
}

-(void)updateTime {
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"hh:mm"];
    NSString *dateString = [dateFormat stringFromDate:today];
    [timeLabel setText:dateString];
    [dateFormat release];
}

#pragma mark Active & deactive

- (void)setActive:(BOOL)active{
    NSLog(@"CSApplicationController setActive");
	[self setActive:active animated:YES];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated{
    NSLog(@"CSApplicationController setActive:animated");
    if (active == self.isActive || self.isAnimating) { return; } //We are already active/inactive 

	if (active)
        [self activateAnimated:animated];
	else
        [self deactivateAnimated:animated];
}

-(void)activateAnimated:(BOOL)animate{
    NSLog(@"CSApplicationController activateAnimated");
    self.isActive = YES;

    self.layer.transform = CATransform3DIdentity;

    self.frame = [UIScreen mainScreen].bounds;

    [self checkPages];
    [self relayoutSubviews];
    [self checkPages];

    // Setup first then animation
    self.hidden = NO;
    self.alpha = 0.0f;
    self.isAnimating = YES;
    self.userInteractionEnabled = YES;
    self.scrollView.userInteractionEnabled = YES;
    self.layer.transform = CATransform3DMakeScale(3.5f, 3.5f, 1.0f);

    [UIView animateWithDuration:(animate ? 0.4 : 0.0) animations:^{
        self.alpha = 1;
        self.layer.transform = CATransform3DIdentity;
    } completion:^(BOOL finished){
        self.isAnimating = NO;
        [self checkPages];
        //[self fadeInScrollView];
        //if (spoke) { spoke = NO, [speaker startSpeakingString:@"Welcome to CardSwitcher"]; }
    }];
}

-(void)fadeInScrollView {
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.alpha = 1.0;
    }];
}

-(void)deactivateAnimated:(BOOL)animate{
    NSLog(@"CSApplicationController deactivateAnimated");
    
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    if (animate && !(runningApp == nil)) {

        if ([(SpringBoard *)[UIApplication sharedApplication] respondsToSelector:@selector(setBackgroundingEnabled:forDisplayIdentifier:)] && [CSResources autoBackgroundApps]){
            NSLog(@"CSApplicationController deactivateAnimated: SPRINGBOARD responds to selector");
			[(SpringBoard *)[UIApplication sharedApplication] setBackgroundingEnabled:YES forDisplayIdentifier:runningApp.displayIdentifier];
            NSLog(@"CSApplicationController deactivateAnimated: SPRINGBOARD setBackgroundingEnabled:forDisplayIdentifier");
        }

        [CSApplicationController sharedController].shouldAnimate = YES;
        if (![CSResources goHomeOnHomeButton] && !(self.exitingAllApps)) {
            [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:runningApp];
        }
    }
    
    // Custom animation when closing on an app.
    CGRect screenRect = self.frame;
    screenRect.size.width = SCREEN_WIDTH;
    screenRect.size.height = SCREEN_HEIGHT;
    screenRect.origin.x = -[CSApplicationController sharedController].scrollView.frame.origin.x - (([CSApplicationController sharedController].scrollView.frame.size.width-self.frame.size.width)*0.5);
    screenRect.origin.y = -[CSApplicationController sharedController].scrollView.frame.origin.y;
    
    self.isActive = NO;
    self.userInteractionEnabled = NO;
    self.scrollView.userInteractionEnabled = NO;
    self.layer.transform = CATransform3DIdentity;

    [self setRotation:[[UIDevice currentDevice] orientation]];

    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if (self.pressedHome) {
        // Get current image to do our animations with
        CGImageRef screen = UIGetScreenImage();
        UIImageView *winmoUi = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        winmoUi.image = [UIImage imageWithCGImage:screen scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationUp];
        CGImageRelease(screen);
    
        winmoUi.opaque = NO;
        winmoUi.backgroundColor = [UIColor clearColor];
        
        [self addSubview:winmoUi];
        
        // Deactivation animations
        if ([CSResources closeAnimation] == 2) {
            // We want the sliding animation
            CGRect newFrame = winmoUi.frame;
            CGRect oldFrame = winmoUi.frame;
        
            newFrame.origin.x = -SCREEN_WIDTH;
            
            for (UIView *view in self.scrollView.subviews) {
                [view removeFromSuperview];
            }
            
            [noAppsLabel removeFromSuperview];
            noAppsLabel = nil;
            
            [timeLabel removeFromSuperview];
            timeLabel = nil;
            
            [backgroundView removeFromSuperview];
            backgroundView = nil;
            
            [exitButton removeFromSuperview];
            exitButton = nil;
            
            /*[exitBar removeFromSuperview];
            exitBar = nil;*/
        
            [UIView animateWithDuration:0.3 animations:^{
                self.isAnimating = YES;
                winmoUi.frame = newFrame;
            } completion:^(BOOL finished){
                self.hidden = YES;
                self.isAnimating = NO;
                self.pressedHome = NO;
                winmoUi.frame = oldFrame;
                
                [CSResources reset];
                
                [winmoUi removeFromSuperview];
                [winmoUi release];
                
            }];
        } else {
            // We want the rotating animation
            CGRect frame = winmoUi.frame;
            
            winmoUi.layer.anchorPoint = CGPointMake(0.0f, 0.0f);
            winmoUi.layer.frame = frame;
    
            CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
            rotationAndPerspectiveTransform.m34 = 1.0 / 1500;
            //rotationAndPerspectiveTransform.m34 = 0;
            rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, M_PI/2, 0, 1, 0);
    
            for (UIView *view in self.scrollView.subviews) {
                [view removeFromSuperview];
            }
            
            [noAppsLabel removeFromSuperview];
            noAppsLabel = nil;
            
            [timeLabel removeFromSuperview];
            timeLabel = nil;
            
            [backgroundView removeFromSuperview];
            backgroundView = nil;
            
            [exitButton removeFromSuperview];
            exitButton = nil;
            
            /*[exitBar removeFromSuperview];
            exitBar = nil;*/
            
            [UIView animateWithDuration:(animate ? 0.3 : 0.0) animations:^{
                self.isAnimating = YES;
                //self.layer.transform = CATransform3DMakeScale(2.5f, 2.5f, 1.0f);
                // http://stackoverflow.com/questions/13887016/catransform3d-animation-set-x-axis
                winmoUi.layer.transform = rotationAndPerspectiveTransform;
                //self.alpha = 0.0f;
            } completion:^(BOOL finished){
                self.hidden = YES;
                self.isAnimating = NO;
                self.pressedHome = NO;

                [CSResources reset];
                
                [winmoUi removeFromSuperview];
                [winmoUi release];
            }];
        }
        // Make sure we remove things from superview when launching apps/locking device too
    } else if (self.applaunching || self.isLocking) {
        self.isAnimating = YES;
        self.hidden = YES;
        self.isAnimating = NO;
        self.applaunching = NO;
            
        [CSResources reset];
            
        for (UIView *view in self.scrollView.subviews) {
            [view removeFromSuperview];
        }
            
        [noAppsLabel removeFromSuperview];
        noAppsLabel = nil;
            
        [timeLabel removeFromSuperview];
        timeLabel = nil;
            
        [backgroundView removeFromSuperview];
        backgroundView = nil;
            
        [exitButton removeFromSuperview];
        exitButton = nil;
    }
    
    // Logic to sort out exiting all apps (otherwise, dragons will fly out your arse!) Seriously though, we need this code to make sure that exitingAllApps is reset after, well, the exit all apps button is pressed.
    if (self.exitingAllApps) {
        self.exitingAllApps = NO;
    }
}

// Is this code even neccessary now?!
-(void)openApp:(NSString*)bundleId {
    
    // the SpringboardServices.framework private framework can launch apps,
    //  so we open it dynamically and find SBSLaunchApplicationWithIdentifier()
    void* sbServices = dlopen(SBSERVPATH, RTLD_LAZY);
    int (*SBSLaunchApplicationWithIdentifier)(CFStringRef identifier, Boolean suspended) = dlsym(sbServices, "SBSLaunchApplicationWithIdentifier");
    result = SBSLaunchApplicationWithIdentifier((CFStringRef)bundleId, false);
    dlclose(sbServices);
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    [self checkPages];
    //#error SCRAPING 3 visibleApps and adding LAZY image loading.
}

-(void)checkPages{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = (floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1;

    pageControl.numberOfPages = [self.runningApps count];
    pageControl.currentPage = page;

    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * pageControl.numberOfPages, 0);
}


#pragma mark libactivator delegate

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    NSLog(@"CSApplicationController; activator:recieveEvent");
	if ([(SBAwayController*)[objc_getClass("SBAwayController") sharedAwayController] isLocked] || self.isAnimating)
		return;

    // Set the event handled
    [event setHandled:YES];
    BOOL newActive = ![self isActive];
    //[self setActive:newActive];

    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    // Used only if transparent background is enabled
    if ([CSResources backgroundStyle] == 5) {
        transparentImage = [[UIImage alloc] _initWithIOSurface:[UIWindow createScreenIOSurface] scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    }
    
    // SpringBoard is active, just activate
    if (runningApp == nil) {
        [self setActive:newActive];
        [self scrollViewDidScroll:self.scrollView];
        return;
    }
    CGImageRef screen = UIGetScreenImage();

    [CSResources setCurrentAppImage:[UIImage imageWithCGImage:screen]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [CSResources cachScreenShot:[UIImage imageWithCGImage:screen] forApp:runningApp];
    });
    
    CGImageRelease(screen);

    if (newActive && [[runningApp displayIdentifier] length]) {
        openedOverApp = runningApp;
        [self setActive:YES animated:NO];

        SBApplication *application = runningApp;
        int index = [self.runningApps indexOfObject:application];
        [self.scrollView setContentOffset:CGPointMake((index*self.scrollView.frame.size.width), 0) animated:NO];
        [self scrollViewDidScroll:self.scrollView];

        self.scrollView.userInteractionEnabled = NO;
        
        CSApplication *psApp = [self csAppforApplication:application];
        UIImageView *snapshot = psApp.snapshot;

        float oldRadius = snapshot.layer.cornerRadius;
        snapshot.layer.cornerRadius = 0;

        CGRect targetRect = snapshot.frame;

        CGRect screenRect = psApp.frame;
        screenRect.size.width = SCREEN_WIDTH;
        screenRect.size.height = SCREEN_HEIGHT;
        screenRect.origin.x = -self.scrollView.frame.origin.x - ((self.scrollView.frame.size.width-psApp.frame.size.width)*0.5);
        screenRect.origin.y = -self.scrollView.frame.origin.y;
        snapshot.frame = screenRect;

        [self.scrollView bringSubviewToFront:psApp];
        [psApp bringSubviewToFront:psApp.snapshot];

        [UIView animateWithDuration:0.38 animations:^{
            snapshot.frame = targetRect;
            snapshot.layer.cornerRadius = oldRadius;
        } completion:^(BOOL finished){
            [psApp sendSubviewToBack:psApp.snapshot];
            self.scrollView.userInteractionEnabled = YES;
        }];
	}
    else {
        // Fancy animation
        [self setActive:NO];
    }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event{
    NSLog(@"CSApplicationController activator:abortEvent");
    if (self.isActive == NO || self.isAnimating) { return; }

    [self setActive:NO animated:NO];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event{
    NSLog(@"CSApplicationController activator:receiveDeactivateEvent");
    
    // Need to get screenshot of app when home button is pressed -> this is run every time it's pressed, so take screenshot when not active, and in a running app.
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    if (!(self.isActive) && (runningApp != nil)) {
        CGImageRef screen = UIGetScreenImage();
        [CSResources setCurrentAppImage:[UIImage imageWithCGImage:screen]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [CSResources cachScreenShot:[UIImage imageWithCGImage:screen] forApp:runningApp];
        });
        CGImageRelease(screen);
    }
    
    if ([CSResources goHomeOnHomeButton] && !(runningApp == nil) && self.isActive) {
        [runningApp notifyResumeActiveForReason:1];
        [(SpringBoard *)[UIApplication sharedApplication] quitTopApplication:nil];
    }
    
    if (self.isActive == NO || self.isAnimating) { return; }

    [event setHandled:YES];
    self.pressedHome = YES;
    [self setActive:NO];
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    [noAppsLabel release], noAppsLabel = nil;
    [pageControl release], pageControl = nil;
    
    [super dealloc];
}

// This section from Micah Hainline (http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string)
-(UIColor *)colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

-(CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

@end
