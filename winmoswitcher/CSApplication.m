//
//  CSApplication.m
//
//  Created by Kyle Howells on 06/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//////////////////////////////////////////
// 2 best methods, the SBIcon one will likely be gone with iOS 5.0 so I'm noting down the UIImage method. 
// UIImage *icon = [UIImage _applicationIconImageForBundleIdentifier:[app bundleIdentifier] roleIdentifier:[app roleIdentifier] format:0];
// "format:" & "getIconImage:" need an int. I think that they both use a typedef something like this.
/// (Note: must check the icons that are same size at some point to see if they really are the same)
/*
 * |	typedef enum {
 * |	    SBIconTypeSmall = 1,    // Settings icon (29*29)
 * |	    SBIconTypeLarge = 2,    // SpringBoard icon (59*62)
 * |	    SBIconTypeMedium = 3,   // Don't know? (43*43.5)
 * |	    SBIconTypeBig = 4,	    // SpringBoard icon again? (59*62)
 * |	    SBIconTypeMiddle = 5,   // Slightly bigger settings icon? (31*37)
 * |	    SBIconTypeMid = 6,	    // Same size as 5, might not be same though? (31*37)
 * |	    SBIconTypeError = 7     // Calling this gives an error ("[NSCFString size]: unrecognized selector")
 * |				    // Anything above 7 returns nil.
 * |	} SBIconType;
 */


/// SpringBoard headers
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import "CSApplicationController.h"
#import <QuartzCore/QuartzCore.h>
#import "CSApplication.h"
#import "CSScrollView.h"
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <dispatch/dispatch.h>

#define BUNDLE @"/Library/Application Support/WinMoSwitcher/WinMoSwitcher.bundle"

/*@interface SBIconModel ()
- (SBApplicationIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end*/

@interface SBApplicationIcon ()
- (BOOL)hasBadge;
@end

/*@interface SBIconBadge ()
+(id)iconBadgeWithBadgeString:(NSString *)badgeString;
@end*/

/*@interface SBUIController ()
- (void)activateApplicationFromSwitcher:(SBApplication *)application;
@end*/

@interface SBApplication ()
-(int)suspensionType;
-(int)_suspensionType;
-(void)setSuspendType:(int)suspendType;
//-(id)process;
@end

@interface SBProccess : NSObject {}
-(void)resume;
@end

@interface SBIcon (PSText)
-(NSString*)_PSBadgeText;
@end


//#error TODO: Change over UI from the controller to seperate CSApplication objects.

#define APP self.application

static CSApplication *_instance;

@implementation CSApplication
@synthesize label = _label;
@synthesize icon = _icon;
@synthesize badge = _badge;
@synthesize appImage = _appImage;
@synthesize closeBox = _closeBox;
@synthesize snapshot = _snapshot;
@synthesize application = _application;

+(CSApplication*)sharedController {
    if (!_instance) {
        _instance = [[CSApplication alloc] init];
    }
    
    return _instance;
}

-(id)init {
    NSLog(@"CSApplication; init");
    if ((self = [super initWithFrame:CGRectMake(0, 0, (SCREEN_WIDTH*0.625), [UIScreen mainScreen].bounds.size.height)])) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        self.clipsToBounds = NO;
        // Autoresizing masks
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.application = nil;
        self.appImage = nil;

        self.snapshot = [[[UIImageView alloc] init] autorelease];
        self.snapshot.backgroundColor = [UIColor clearColor];
        self.snapshot.frame = CGRectMake(0, (SCREEN_HEIGHT*0.16), (SCREEN_WIDTH*0.625), (SCREEN_HEIGHT*0.625));
        self.snapshot.userInteractionEnabled = YES;
        self.snapshot.layer.masksToBounds = YES;
        self.snapshot.layer.cornerRadius = [CSResources cornerRadius];
        self.snapshot.layer.borderWidth = 0;
        self.snapshot.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
        [self addSubview:self.snapshot];

        UISwipeGestureRecognizer *swipeUp = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeGesture:)] autorelease];
        swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        [self.snapshot addGestureRecognizer:swipeUp];

        UITapGestureRecognizer *singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchGesture:)] autorelease];
        [singleTap requireGestureRecognizerToFail:swipeUp];
        singleTap.numberOfTapsRequired = [CSResources tapsToLaunch];
        [self addGestureRecognizer:singleTap];

        self.icon = [[[UIImageView alloc] init] autorelease];
        self.icon.frame = CGRectMake(17, self.snapshot.frame.size.height + self.snapshot.frame.origin.y + 14, self.icon.frame.size.width, self.icon.frame.size.height);
        [self addSubview:self.icon];

        self.closeBox = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeBox.frame = CGRectMake(0, 0, 45, 45);
        self.closeBox.center = self.snapshot.frame.origin;
        [self.closeBox setImage:[CSApplicationController sharedController].closeBox forState:UIControlStateNormal];
        [self.closeBox addTarget:self action:@selector(quitPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBox];
        self.closeBox.hidden = ![CSResources showsCloseBox];
        
        CGRect labelRect;
        labelRect.origin.x = (self.icon.frame.origin.x + self.icon.frame.size.width + 12);
        labelRect.origin.y = self.icon.frame.origin.y;
        labelRect.size.width = (self.snapshot.frame.origin.x + self.snapshot.frame.size.width)-(self.icon.frame.size.width + self.icon.frame.origin.x + 10);
        labelRect.size.height = self.icon.frame.size.height;

        self.label = [[[UILabel alloc] initWithFrame:labelRect] autorelease];
        self.label.font = [UIFont boldSystemFontOfSize:17];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.numberOfLines = 0;
        self.label.text = @"Application";
        [self addSubview:self.label];
        self.label.hidden = ![CSResources showsAppTitle];


        [[CSApplicationController sharedController].scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];

        [pool release];
    }

    return self;
}

-(void)loadImages {
    if (self.appImage != nil)
        return;

    self.appImage = [CSResources cachedScreenShot:APP];
    self.snapshot.image = self.appImage;
}
-(void)reset {
    NSLog(@"CSApplication; reset");
    self.appImage = nil;
    self.snapshot.image = nil;
}

-(id)initWithApplication:(SBApplication*)application {
    NSLog(@"CSApplication; initWithApplication");
    if ((self = [super initWithFrame:CGRectMake(0, 0, (SCREEN_WIDTH*0.625), [UIScreen mainScreen].bounds.size.height)])) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        self.clipsToBounds = NO;
        // Autoresizing masks
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.application = application;
        self.appImage = nil;

        self.snapshot = [[[UIImageView alloc] initWithFrame:CGRectMake(0, (SCREEN_HEIGHT*0.16), (SCREEN_WIDTH*0.625), (SCREEN_HEIGHT*0.625))] autorelease];
        self.snapshot.backgroundColor = [UIColor clearColor];
        self.snapshot.userInteractionEnabled = YES;
        self.snapshot.layer.masksToBounds = YES;
        self.snapshot.layer.cornerRadius = [CSResources cornerRadius];
        self.snapshot.layer.borderWidth = 0;
        self.snapshot.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
        [self addSubview:self.snapshot];

        UISwipeGestureRecognizer *swipeUp = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeUpGesture:)] autorelease];
        swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        [self.snapshot addGestureRecognizer:swipeUp];
        
        UISwipeGestureRecognizer *downSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeDownGesture:)] autorelease];
        downSwipe.direction = UISwipeGestureRecognizerDirectionDown;
        [self.snapshot addGestureRecognizer:downSwipe];

        UITapGestureRecognizer *singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchGesture:)] autorelease];
        [singleTap requireGestureRecognizerToFail:swipeUp];
        [singleTap requireGestureRecognizerToFail:downSwipe];
        singleTap.numberOfTapsRequired = [CSResources tapsToLaunch];
        [self addGestureRecognizer:singleTap];

        //*************************** FIXME!!!!!!!!!!!!!!! ******************************
        
         // Application badges
        /*if ([appIcon hasBadge]) {
            self.badge = [objc_getClass("SBIconBadge") iconBadgeWithBadgeString:[appIcon _PSBadgeText]]; //[[appIcon badgeView] _PSBadgeText]];
            self.badge.center = CGPointMake((self.snapshot.frame.size.width - (self.badge.frame.size.width*0.2)), self.snapshot.frame.origin.y + (self.badge.frame.size.height*0.2));
            [self addSubview:self.badge];
        }*/
        
        // Get app icon
        BOOL showsAppIcon = [CSResources showsAppIcon];
        if (showsAppIcon && ![[APP displayIdentifier] isEqual:@"com.apple.springboard"]) {
            SBApplicationIcon *appIcon = [[objc_getClass("SBApplicationIcon") alloc] initWithApplication:APP];
            UIImage *icon = [appIcon generateIconImage:1];
            self.icon = [[[UIImageView alloc] initWithImage:icon] autorelease];
            self.icon.frame = CGRectMake(1, self.snapshot.frame.size.height + self.snapshot.frame.origin.y + 5, self.icon.frame.size.width, self.icon.frame.size.height);
            [self addSubview:self.icon];
            
            [appIcon release];
        }
        
        // Badges
        /*SBApplicationIcon *appIcon = [[objc_getClass("SBApplicationIcon") alloc] initWithApplication:APP];
        if ([appIcon hasBadge]) {
            NSString *badgeValue = [appIcon badgeValue];
            
            // Add to image
            UIImage *badgeBG = [UIImage imageWithContentsOfFile:@"/Library/Application Support/WinMoSwitcher/Badgebg.png"];
            UIImage *badge = [self drawText:badgeValue inImage:badgeBG atPoint:CGPointMake((badgeBG.size.width - (badgeBG.size.width/2)), (badgeBG.size.height - (badgeBG.size.height/2)))];
            self.badge.image = badge;
            
            self.badge.center = CGPointMake((self.snapshot.frame.size.width - (self.badge.frame.size.width*0.2)), self.snapshot.frame.origin.y + (self.badge.frame.size.height*0.2));
            [self addSubview:self.badge];
        }
        [appIcon release];*/
        
        // Close box
        self.closeBox = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeBox.frame = CGRectMake(0, 0, 45, 45);
        self.closeBox.center = self.snapshot.frame.origin;
        [self.closeBox setImage:[CSApplicationController sharedController].closeBox forState:UIControlStateNormal];
        [self.closeBox addTarget:self action:@selector(quitPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBox];
        self.closeBox.hidden = ![CSResources showsCloseBox];
        
        // Application label
        CGRect labelRect;
        if (showsAppIcon && ![[APP displayIdentifier] isEqual:@"com.apple.springboard"]) {
            labelRect.origin.x = (self.icon.frame.origin.x + self.icon.frame.size.width + 7);
            labelRect.origin.y = self.icon.frame.origin.y;
            labelRect.size.width = (self.snapshot.frame.origin.x + self.snapshot.frame.size.width)-(self.icon.frame.size.width + self.icon.frame.origin.x + 10);
            labelRect.size.height = self.icon.frame.size.height;
        } else {
            labelRect.origin.x = (self.snapshot.frame.origin.x + 4);
            labelRect.origin.y = (self.snapshot.frame.size.height + self.snapshot.frame.origin.y + 5);
            labelRect.size.width = self.snapshot.frame.size.width;
            labelRect.size.height = 20;
        }

        self.label = [[[UILabel alloc] initWithFrame:labelRect] autorelease];
        self.label.font = [UIFont systemFontOfSize:14];
        self.label.backgroundColor = [UIColor clearColor];
        if ([CSResources backgroundStyle] == 3) {
            self.label.textColor = [UIColor blackColor];
        } else {
            self.label.textColor = [UIColor whiteColor];
        }
        self.label.numberOfLines = 0;
        if ([[APP displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
            NSBundle *bundle = [[NSBundle alloc] initWithPath:BUNDLE];
            self.label.text = [bundle localizedStringForKey:@"START" value:@"Start" table:nil];
            [bundle release];
        } else {
        self.label.text = [APP displayName];
        }
        [self addSubview:self.label];
        self.label.hidden = ![CSResources showsAppTitle];

        [[CSApplicationController sharedController].scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];
        
        [pool release];
    }

    return self;
}

-(UIImage*)drawText:(NSString*)text inImage:(UIImage*)image atPoint:(CGPoint)point {
    UIFont *font = [UIFont systemFontOfSize:12];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor whiteColor] set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)launch {
    NSLog(@"CSApplication; launch");
    [self.superview bringSubviewToFront:self];
    [self bringSubviewToFront:self.snapshot];
    [CSApplicationController sharedController].scrollView.userInteractionEnabled = NO;
    [CSApplicationController sharedController].applaunching = YES;
    
    [UIView animateWithDuration:0.1 animations:^{
        //self.badge.alpha = 0;
        self.closeBox.alpha = 0;
        self.label.alpha = 0.0f;
    }completion:^(BOOL finished){}];

    // But either way I want my custom animation.
    CGRect screenRect = self.frame;
    screenRect.size.width = SCREEN_WIDTH;
    screenRect.size.height = SCREEN_HEIGHT;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        screenRect.origin.x = -[CSApplicationController sharedController].scrollView.frame.origin.x - (([CSApplicationController sharedController].scrollView.frame.size.width-self.frame.size.width)*0.5)+60;    // Need to adjust for iPhone 3GS though
    } else {
        screenRect.origin.x = -[CSApplicationController sharedController].scrollView.frame.origin.x - (([CSApplicationController sharedController].scrollView.frame.size.width-self.frame.size.width)*0.5)+(144*IPAD_X_SCALE);
    }
    screenRect.origin.y = -[CSApplicationController sharedController].scrollView.frame.origin.y;

    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    // If we can open the app without the usual iOS animation, or force iOS to give a faster animation, then we won't have weird effects at the end of ours. Could use [CSApplicationController openApp:[APP displayIdentifier]];
    if (runningApp != nil) {
        // An app is already open, so use the switcher animation, but first check if this is the same app.
        if (![[runningApp bundleIdentifier] isEqualToString:[APP bundleIdentifier]]) {
            if ([[APP displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
                // Close the topmost app if we're opening SpringBoard
                [(SpringBoard *)[UIApplication sharedApplication] quitTopApplication:nil];
            } else {
                [CSApplicationController sharedController].shouldAnimate = YES;
                [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:APP];
            }
        }
    } else {
        // Else we are on SpringBoard
        if ([[APP displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
            // Close the topmost app if we're opening SpringBoard
            [(SpringBoard *)[UIApplication sharedApplication] quitTopApplication:nil];
        } else {
            [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:APP];
        }
    }
    
    /*static SBWorkspace *workspace$ = nil;
    static id scheduledTransaction$ = nil;
    
    SBAlertManager *alertManager = workspace$.alertManager;
    SBAppToAppWorkspaceTransaction *transaction = [[objc_getClass("SBAppToAppWorkspaceTransaction") alloc]
                                                   initWithWorkspace:workspace$.bksWorkspace alertManager:alertManager from:fromApp to:toApp];
    if ([workspace$ currentTransaction] == nil) {
        [workspace$ setCurrentTransaction:transaction];
    } else if (scheduledTransaction$ == nil) {
        // NOTE: Don't schedule more than one transaction.
        scheduledTransaction$ = [transaction retain];
    }
    [transaction release];*/
    
    UIView *snapshotAnim = self.snapshot;
    [[CSApplicationController sharedController] addSubview:snapshotAnim];
    
    CGRect snapshotNewRect = self.snapshot.frame;
    
    // Compensate for some UI weirdness ;P
    int extra = ((SCREEN_WIDTH/2)-(self.snapshot.frame.size.width/2));
    snapshotNewRect.origin.x = self.snapshot.frame.origin.x+extra;
    
    snapshotAnim.frame = snapshotNewRect;
    
    // 1. Launch animation
    [UIView animateWithDuration:0.6 animations:^{
        snapshotAnim.frame = screenRect;
        snapshotAnim.layer.cornerRadius = 0;
    } completion:^(BOOL finished){
        [[CSApplicationController sharedController] setActive:NO animated:NO];
        [[CSApplicationController sharedController] sendSubviewToBack:snapshotAnim];
        [snapshotAnim removeFromSuperview];
    }];

    int appIndex = [[CSApplicationController sharedController].runningApps indexOfObject:APP];
    int numToRight = [[CSApplicationController sharedController].runningApps count]-appIndex;
    int lengthToMove = numToRight+1;
    
    if ( !(appIndex == [[CSApplicationController sharedController].runningApps count]-1) ) {
        // 2. Animate the scrollview moving to the left
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self animateScrollView:lengthToMove];
        });
    }
    
    // 3. Fade out the snapshot's label and the time label
    [UIView animateWithDuration:0.4 animations:^{
        [CSApplicationController sharedController].timeLabel.alpha = 0.0f;
    }];
}

-(void)animateScrollView:(int)lengthToMove {
    if ([CSApplicationController sharedController].runningApps.count > 1) {
        CGRect scrollRect = [CSApplicationController sharedController].scrollView.frame;
        CGRect oldScrollRect = [CSApplicationController sharedController].scrollView.frame;
        scrollRect.origin.x = 0-[CSApplicationController sharedController].scrollView.frame.size.width*lengthToMove;
        [UIView animateWithDuration:0.6 animations:^{
            [CSApplicationController sharedController].scrollView.frame = scrollRect;
        } completion:^(BOOL finished){
            // Put it back into original position
            [CSApplicationController sharedController].scrollView.frame = oldScrollRect;
        }];
    }
}

-(void)exit {
    NSLog(@"CSApplication; exit");
    [self retain];

    //[[CSApplicationController sharedController].ignoreRelaunchID release], [CSApplicationController sharedController].ignoreRelaunchID = nil;
    //[CSApplicationController sharedController].ignoreRelaunchID = [APP.displayIdentifier retain];
    
    [[CSApplicationController sharedController] appQuit:APP];
    [self removeFromSuperview];


    //******************* Proper app quiting code thanks to 'jmeosbn', but heavily modified - start **************//

    // Set app to terminate on suspend then call deactivate
    // Allows exiting root apps, even if already backgrounded,
    // but does not exit an app with active background tasks
    
    // Damn. Root apps aren't terminated.
    //[APP _setActivationState:0];
    // Allow application to suspend, so killing will be graceful
    [APP notifyResignActiveForReason:1];
    [APP deactivate];
    
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    // Make sure that the top application is closed gracefully, and we're taken back to SpringBoard
    if ([[APP displayIdentifier] isEqual:[runningApp displayIdentifier]]) {
        [(SpringBoard *)[UIApplication sharedApplication] quitTopApplication:nil];
    }
    
    [self performSelector:@selector(killItWithFire) withObject:nil afterDelay:2];

    //******************* Proper app quiting code thanks to 'jmeosbn' - end **************//

    [self release];
}

-(void)killItWithFire {
    // Let's make ourselves root to kill those pesky root applications! Except, that doesn't work.
    setuid(0);
    if ([APP pid] > 0)
        kill([APP pid], SIGTERM);
}

-(void)exitAllApps {
    NSLog(@"Exit all apps");
    [CSApplicationController sharedController].exitingAllApps = YES;
    [self retain];
    NSMutableArray *toRemove = [NSMutableArray array];
    for (SBApplication *app in [CSApplicationController sharedController].runningApps) {
        // First, check if it's in our exclusion list.
        // Then, if it's excluded, or is SpringBoard, don't run the code!
        if (![CSResources excludeFromExiting:app] && ![[app displayIdentifier] isEqual:@"com.apple.springboard"]) {
            // Prevent runningApps array from being mutated while enumerating
            [toRemove addObject:app];
        
            [app notifyResignActiveForReason:1];
            [app deactivate];
            SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
            if ([[app displayIdentifier] isEqual:[runningApp displayIdentifier]]) {
                [(SpringBoard *)[UIApplication sharedApplication] quitTopApplication:nil];
            }
        
            [self performSelector:@selector(killItWithFireMkTwo:) withObject:app afterDelay:2];
        }
    }
    
    for (SBApplication *app in toRemove) {
        [[CSApplicationController sharedController] appQuit:app];
    }
    
    [[CSApplicationController sharedController] showAlertWithTitle:@"Test"
                                                              body:@"TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TST TSTTSTTSTSTSTTSTS" andCloseButton:@"close"];
    
    [self release];
}
-(void)killItWithFireMkTwo:(SBApplication *)app {
    // Let's make ourselves root to kill those pesky root applications! Except, that doesn't work.
    setuid(0);
    if ([app pid] > 0)
        kill([app pid], SIGTERM);
}

-(void)quitPressed {
    NSLog(@"CSApplication; quitPressed");
    [UIView animateWithDuration:0.2 animations:^{
        self.icon.alpha = 0;
        self.label.alpha = 0;
        //self.badge.alpha = 0;
        self.closeBox.alpha = 0;
    } completion:^(BOOL finished){}];

    [UIView animateWithDuration:0.4 animations:^{
        self.snapshot.alpha = 0;
        self.snapshot.frame = CGRectMake(0, -self.snapshot.frame.size.height, self.snapshot.frame.size.width, self.snapshot.frame.size.height);
    } completion:^(BOOL finished){
        [self exit];
    }];
}


-(void)launchGesture:(UITapGestureRecognizer*)gesture {
    NSLog(@"CSApplication; launchGesture");
    if (gesture.state != UIGestureRecognizerStateEnded)
        return;

    [self launch];
}

-(void)closeDownGesture:(UIGestureRecognizer*)gesture {
    NSLog(@"CSApplication; closeGesture");
    if (gesture.state != UIGestureRecognizerStateEnded || ![CSResources swipeCloses])
        return;
    
    // Ensure that SpringBoard cannot be closed
    if ([[APP displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
        
        CGRect frameOld = self.snapshot.frame;
        CGRect frameNew = self.snapshot.frame;
        
        frameNew.origin.y = frameNew.origin.y+(SCREEN_HEIGHT*0.15);
        
        [UIView animateWithDuration:0.2 animations:^{
            self.label.alpha = 0;
            self.snapshot.frame = frameNew;
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.1 animations:^{
                self.label.alpha = 1;
                self.snapshot.frame = frameOld;
            }];
        }];
        return;
    }
    
    CGRect labelRect = self.label.frame;
    CGRect iconRect;
    CGRect snapshotRect = self.snapshot.frame;
    
    snapshotRect.origin.y = self.snapshot.frame.size.height*2;
    
    if ([CSResources showsAppIcon] && ![[APP displayIdentifier] isEqual:@"com.apple.springboard"]) {
        iconRect = self.icon.frame;
        iconRect.origin.y = snapshotRect.size.height + snapshotRect.origin.y + 5;
        labelRect.origin.y = (iconRect.origin.y);
    } else {
        labelRect.origin.y = (snapshotRect.size.height + snapshotRect.origin.y + 5);
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        //self.badge.alpha = 0;
        self.closeBox.alpha = 0;
    } completion:^(BOOL finished){}];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.snapshot.alpha = 0;
        self.snapshot.frame = snapshotRect;
        self.label.frame = labelRect;
        self.label.alpha = 0;
        if ([CSResources showsAppIcon] && ![[APP displayIdentifier] isEqual:@"com.apple.springboard"]) {
            self.icon.alpha = 0;
            self.icon.frame = iconRect;
        }
    } completion:^(BOOL finished){
        [self exit];
    }];
}

-(void)closeUpGesture:(UIGestureRecognizer*)gesture {
    NSLog(@"CSApplication; closeGesture");
    if (gesture.state != UIGestureRecognizerStateEnded || ![CSResources swipeCloses])
        return;
    
    // Ensure that SpringBoard cannot be closed
    if ([[APP displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
        
        CGRect frameOld = self.snapshot.frame;
        CGRect frameNew = self.snapshot.frame;
        
        frameNew.origin.y = frameNew.origin.y-(SCREEN_HEIGHT*0.15);
        
        [UIView animateWithDuration:0.2 animations:^{
            self.snapshot.frame = frameNew;
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.1 animations:^{
                self.snapshot.frame = frameOld;
            }];
        }];
        return;
    }

    CGRect labelRect = self.label.frame;
    CGRect iconRect;
    CGRect snapshotRect = self.snapshot.frame;
    
    snapshotRect.origin.y = -self.snapshot.frame.size.height;
    
    if ([CSResources showsAppIcon] && ![[APP displayIdentifier] isEqual:@"com.apple.springboard"]) {
        iconRect = self.icon.frame;
        iconRect.origin.y = snapshotRect.size.height + snapshotRect.origin.y + 5;
        labelRect.origin.y = (iconRect.origin.y);
    } else {
        labelRect.origin.y = (snapshotRect.size.height + snapshotRect.origin.y + 5);
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        //self.badge.alpha = 0;
        self.closeBox.alpha = 0;
    } completion:^(BOOL finished){}];

    [UIView animateWithDuration:0.3 animations:^{
        self.snapshot.alpha = 0;
        self.snapshot.frame = snapshotRect;
        self.label.frame = labelRect;
        self.label.alpha = 0;
        if ([CSResources showsAppIcon] && ![[APP displayIdentifier] isEqual:@"com.apple.springboard"]) {
            self.icon.alpha = 0;
            self.icon.frame = iconRect;
        }
    } completion:^(BOOL finished){
        [self exit];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self performSelector:(SEL)context withObject:change];
}

- (void)updateAlpha:(NSDictionary *)change {
    /*CGFloat offset = [CSApplicationController sharedController].scrollView.contentOffset.x;
    CGFloat origin = self.frame.origin.x;
    CGFloat delta = fabs(origin - offset);

    if (delta < self.frame.size.width) {
        self.alpha = 1 - delta/self.frame.size.width*0.8;
    } else {
        self.alpha = 0.3;
    }*/

    if ([[CSApplicationController sharedController].scrollView viewIsVisible:self]) {
        [self loadImages];
    }
    else {
        [self reset];
    }
}


-(void)dealloc {
    NSLog(@"CSApplication; dealloc");
    [[CSApplicationController sharedController].scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self removeObserver:self forKeyPath:@"frame"];

    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }

    self.application = nil;
    self.snapshot = nil;
    self.appImage = nil;
    self.closeBox = nil;
    self.badge = nil;
    self.label = nil;
    self.icon = nil;

    [super dealloc];
}


@end
