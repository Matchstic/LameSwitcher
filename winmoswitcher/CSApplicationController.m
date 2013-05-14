//
//  CSApplicationController.m
//  
//
//  Created by Kyle Howells on 21/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard/SpringBoard.h>
#import "CSApplicationController.h"
#import "CSApplication.h"
#import "CSResources.h"

#define STRIFE_PREFS @"/var/mobile/Library/DreamBoard/Strife/Info.plist"

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



static CSApplicationController *_instance;

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
        self.ignoredIDs = nil;
        //[NSMutableArray arrayWithObjects:@"com.apple.mobileipod-MediaPlayer", @"com.apple.mobilephone", @"com.apple.mobilemail", @"com.apple.mobilesafari", nil];

        pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0f, self.frame.size.height - 28.0f, self.frame.size.width, 20.0f)];
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

        noAppsLabel = nil;
        backgroundView = nil;
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

    self.backgroundColor = [UIColor blackColor];
    
    // Change background as appropriate
    [backgroundView removeFromSuperview];
    backgroundView = nil;
    if ([CSResources backgroundStyle] == 1) {
        // Look's like the user wants the background to be the same as the tile colour.
        backgroundView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
        // Get RBG from hex value, and add into an image
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/DreamBoard/Strife/Info.plist"];
        NSString *tileColour = [dict objectForKey:@"AccentColorHex"];
        CGRect rect = [[UIScreen mainScreen] bounds];
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
            
        CGContextSetFillColorWithColor(context, [[self colorWithHexString:tileColour] CGColor]);
        CGContextFillRect(context, rect);
            
        UIImage *tile = UIGraphicsGetImageFromCurrentImageContext();
        backgroundView.image = tile;
        [tile release];
        [dict release];
        UIGraphicsEndImageContext();
        [self insertSubview:backgroundView atIndex:0];
    }

    [noAppsLabel removeFromSuperview];
    noAppsLabel = nil;

    if ([self.runningApps count] == 0) {
        noAppsLabel = [[[UILabel alloc] initWithFrame:self.frame] autorelease];
        noAppsLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
        noAppsLabel.font = [UIFont boldSystemFontOfSize:17];
        noAppsLabel.textAlignment = NSTextAlignmentCenter;
        noAppsLabel.textColor = [UIColor whiteColor];
        noAppsLabel.text = @"No Apps Running";
        [self addSubview:noAppsLabel];
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
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
        //if (spoke) { spoke = NO, [speaker startSpeakingString:@"Welcome to CardSwitcher"]; }
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

        [runningApp setDeactivationSetting:0x2 flag:NO];
        //[SBWActiveDisplayStack popDisplay:runningApp];
        [self openApp:[runningApp displayIdentifier]];
        //[SBWSuspendingDisplayStack pushDisplay:runningApp];
        runningApp = nil;
        NSLog(@"About to exit (animate && !(runningApp == nil))");
    }

    self.isActive = NO;
    self.userInteractionEnabled = NO;
    self.scrollView.userInteractionEnabled = NO;
    self.layer.transform = CATransform3DIdentity;
    NSLog(@"Set the variables");

    [self setRotation:[[UIDevice currentDevice] orientation]];

    NSLog(@"Set the orientation");
    [UIView animateWithDuration:(animate ? 0.4 : 0.0) animations:^{
        self.isAnimating = YES;
        self.layer.transform = CATransform3DMakeScale(2.5f, 2.5f, 1.0f);
        self.alpha = 0.0f;
    } completion:^(BOOL finished){
        self.hidden = YES;
        self.isAnimating = NO;

        [CSResources reset];
        
        NSLog(@"ABout to remove vies from superview");
        for (UIView *view in self.scrollView.subviews) {
            [view removeFromSuperview];
        }

        NSLog(@"Removed views from superview");
        /*[backgroundView removeFromSuperview];
        NSLog(@"backgroundView removed from superview");
        backgroundView = nil;
        NSLog(@"backgroundView = nil");
        [noAppsLabel removeFromSuperview];
        NSLog(@"noAppsLabel removed from superview");
        noAppsLabel = nil;
        NSLog(@"noAppsLabel = nil");*/
        
        // ******************* A hack to prevent crashes for now, FIXME!!!!!!! **************
        
        backgroundView = nil;
        noAppsLabel = nil;
    }];
}

-(void)openApp:(NSString*)bundleId {
    
    // the SpringboardServices.framework private framework can launch apps,
    //  so we open it dynamically and find SBSLaunchApplicationWithIdentifier()
    void* sbServices = dlopen(SBSERVPATH, RTLD_LAZY);
    int (*SBSLaunchApplicationWithIdentifier)(CFStringRef identifier, Boolean suspended) = dlsym(sbServices, "SBSLaunchApplicationWithIdentifier");
    int result = SBSLaunchApplicationWithIdentifier((CFStringRef)bundleId, false);
    dlclose(sbServices);
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    NSLog(@"CSApplicationController scrollViewDidScroll");
    [self checkPages];
    //#error SCRAPING 3 visibleApps and adding LAZY image loading.
}

-(void)checkPages{
    NSLog(@"CSApplicationController checkPages");
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

    NSLog(@"about to setHandled:YES");
    // Set the event handled
    [event setHandled:YES];
    BOOL newActive = ![self isActive];
    //[self setActive:newActive];
    NSLog(@"Done that, next!");

    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    // SpringBoard is active, just activate
    if (runningApp == nil) {
        NSLog(@"SpringBoard is active...");
        [self setActive:newActive];
        [self scrollViewDidScroll:self.scrollView];
        return;
    }
    
    CGImageRef screen = UIGetScreenImage();
    [CSResources setCurrentAppImage:[UIImage imageWithCGImage:screen]];
    CGImageRelease(screen);

    if (newActive && [[runningApp displayIdentifier] length]) {
        NSLog(@"newActive && [[runningApp displayIdentifier] length]");
        [self setActive:YES animated:NO];

        SBApplication *application = runningApp;
        int index = [self.runningApps indexOfObject:application];
        [self.scrollView setContentOffset:CGPointMake((index*self.scrollView.frame.size.width), 0) animated:NO];
        [self scrollViewDidScroll:self.scrollView];

        self.scrollView.userInteractionEnabled = NO;
        
        NSLog(@"CSApplication psApp");
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
    if (self.isActive == NO || self.isAnimating) { return; }

    [event setHandled:YES];
    [self setActive:NO];
}


-(void)dealloc{
    NSLog(@"CSApplicationController dealloc");
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
