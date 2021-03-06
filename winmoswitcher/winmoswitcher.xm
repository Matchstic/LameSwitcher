#import <SpringBoard/SBApplicationIcon.h>
#import <GraphicsServices/GSCapability.h>
#import <SpringBoard/SBApplication.h>
//#import <SpringBoard/SBIconBadge.h>
#import <libactivator/libactivator.h>
#import "CSApplicationController.h"
#import "CSResources.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <Strife/SLockWindow.h>
#import <Strife/SRootScrollView.h>
#import <SpringBoard/SBAppToAppTransitionController.h>
#import <SpringBoard/SBAppToAppWorkspaceTransaction.h>
#import <SpringBoard/SBUIAnimationController.h>
#import <SpringBoard/SBUISlideAppTransitionView.h>

//UIKIT_EXTERN CGImageRef UIGetScreenImage();

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static NSString * const CARDSWITCHER_ID = @"com.matchstic.winmoswitcher";

/*@interface SBIcon ()
- (id)badgeNumberOrString;
@end*/

// Isn't present in 7.0...
%hook SBAppSwitcherController

-(void)applicationLaunched:(SBApplication*)app {
    %orig;
    
    NSLog(@"SBAppSwitcherController: applicationLaunched");
    [[CSApplicationController sharedController] appLaunched:app];
}

-(void)applicationDied:(SBApplication*)app {
    NSLog(@"SBAppSwitcherController: applicationDied");
    [[CSApplicationController sharedController] appQuit:app];
    
    %orig;
}

%end

// Animation speeding up
%hook SBAppToAppTransitionController

-(void)appTransitionView:(id)fp8 animationWillStartWithDuration:(double)fp12 afterDelay:(double)fp20 {
    NSLog(@"appTransitionView:animationWillStartWithDuration:afterDelay started with animation duration of %f", fp12);
    
    // Make sure we're launching with a shorter animation when in switcher
    if ([CSApplicationController sharedController].applaunching == YES) {
        %orig(fp8, fp12*0.01, fp20*0.5);
    } else {
        %orig;
    }
}

%end

%hook SBAppToAppWorkspaceTransaction

-(void)animationController:(id)fp8 didCommitAnimation:(BOOL)fp12 withDuration:(double)fp16 afterDelay:(double)fp24 {
    NSLog(@"animationController:didCommitAnimation:withDuration:afterDelay: has a duration of %f", fp16);
    if ([CSApplicationController sharedController].applaunching == YES) {
        %orig(fp8, fp12, fp16*0.01, fp24*0.5);
    } else {
        %orig;
    }
}

%end

%hook SBUIAnimationController

-(void)_noteAnimationDidCommit:(BOOL)arg1 withDuration:(double)arg2 afterDelay:(double)arg3 {
    if ([CSApplicationController sharedController].applaunching == YES) {
        %orig(arg1, arg2*0.01, arg3*0.5);
    } else {
        %orig;
    }
}

%end

%hook SBApplicationIcon

-(void)launch{
    %orig;
    [[CSApplicationController sharedController] appLaunched:[self application]];
}

%end


%group OldDevices
%hook SBApplication

-(void)launch{
    %orig;
    
    [[CSApplicationController sharedController] appLaunched:self];
}

%end
%end

%hook SBApplication

-(void)exitedCommon{
    [[CSApplicationController sharedController] appQuit:self];
    
    %orig;
}

-(void)_relaunchAfterExitIfNecessary{
    if ([self.displayIdentifier isEqualToString:[CSApplicationController sharedController].ignoreRelaunchID]) {
        [[CSApplicationController sharedController].ignoreRelaunchID release], [CSApplicationController sharedController].ignoreRelaunchID = nil;
        return;
    }
    
    %orig;
}

%end


%hook SBDisplayStack
-(id)init{
	if ((self = %orig)) {
        NSLog(@"SBDisplayStack: init");
        [[CSApplicationController sharedController].displayStacks addObject:self];
	}
	return self;
}

-(void)dealloc{
    NSLog(@"SBDisplayStack: dealloc");
	[[CSApplicationController sharedController].displayStacks removeObject:self];
    
	%orig;
}
%end


/*%hook SBIcon

%new
-(NSString*)_PSBadgeText{
    if ([[self badgeNumberOrString] isMemberOfClass:[NSNumber class]]) {
        return [[self badgeNumberOrString] stringValue];
    }
    else if ([[self badgeNumberOrString] isMemberOfClass:[NSString class]]) {
        return [self badgeNumberOrString];
    }

    return [[NSNumber numberWithInt:[self badgeValue]] stringValue];
}

%end*/


/*%hook SBIconBadge

%new
-(NSString*)_PSBadgeText{
    if (SYSTEM_VERSION_GREATER_THAN(@"4.1")) {
        NSString *labelText = MSHookIvar<NSString *>(self, "_badge");
        return [[labelText copy] autorelease];
    }

    // If 4.1
    UILabel *label = MSHookIvar<UILabel *>(self, "_badgeLabel");
    return [[label.text copy] autorelease];
}

%end*/


%hook SBAwayController

-(void)lock{
    NSLog(@"SBAwayController: lock");
    [CSApplicationController sharedController].isLocking = YES;
    [[CSApplicationController sharedController] setActive:NO animated:NO];
    
    %orig;
}

%end


%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application{
    %orig;

    //[[CSApplicationController sharedController].runningApps addObject:@"com.apple.springboard"];
    
    [CSApplicationController sharedController].springBoard = self;

    if (![[LAActivator sharedInstance] hasSeenListenerWithName:CARDSWITCHER_ID])
        [[LAActivator sharedInstance] assignEvent:[LAEvent eventWithName:LAEventNameMenuPressDouble] toListenerWithName:CARDSWITCHER_ID];

    [[LAActivator sharedInstance] registerListener:[CSApplicationController sharedController] forName:CARDSWITCHER_ID];


    if (!GSSystemHasCapability(kGSMultitaskingCapability)) {
        %init(OldDevices);
    }
}

%end

/*%group IPAD
%hook SBUIController
- (void)window:(id)arg1 willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(double)arg3{
    %orig;

    [[CSApplicationController sharedController] setRotation:orientation];
}
%end
%end*/


/*%hook SBAppDosadoView
-(void)beginTransition{
    if ([CSApplicationController sharedController].shouldAnimate) {
        CALayer *to = MSHookIvar<CALayer *>(self, "_stopLayer");
        [self.layer addSublayer:to];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.1];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_animationDidStop:)];
        [UIView commitAnimations];
        return;
    }
    
    %orig;
    return;
}

-(void)_beginTransition {
    if ([CSApplicationController sharedController].shouldAnimate) {
        UIView *to = MSHookIvar<UIView *>(self, "_toView");
        [self addSubview:to];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.1];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_animationDidStop:)];
        [UIView commitAnimations];
        return;
    }

    %orig;
    return;
}
-(void)_animationDidStop:(id)_animation{
    [CSApplicationController sharedController].shouldAnimate = NO;

    %orig;
}
%end*/

// Strife hooks

/*%hook SLockWindow

// Get screenshot after unlock
-(void)playLockAndKeypadSeperatingAnimation {
    %orig;
    
    [self performSelector:@selector(getScreenshot) withObject:nil afterDelay:2];
}

%new
-(void)getScreenshot {
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    if (runningApp == nil) {
        CGImageRef screen = UIGetScreenImage();
        [CSResources cachScreenShot:[UIImage imageWithCGImage:screen] forApp:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.apple.springboard"]];
        CGImageRelease(screen);
    }
}
%end

%hook SRootScrollView

// Get screenshot after displaying scroll view
-(id)initWithFrame:(struct CGRect)arg1 {
    %orig;
    
    [self performSelector:@selector(getScreenshot) withObject:nil afterDelay:2];
}
%new
-(void)getScreenshot {
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    if (runningApp == nil) {
        CGImageRef screen = UIGetScreenImage();
        [CSResources cachScreenShot:[UIImage imageWithCGImage:screen] forApp:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.apple.springboard"]];
        CGImageRelease(screen);
    }
}
%end*/

// Spped up app switching
%hook SBUISlideAppTransitionView

-(void)beginTransitionWithDuration:(double)arg1 delay:(double)arg2 {
    if ([CSApplicationController sharedController].applaunching == YES) {
        %orig(arg1*0.01, arg2*0.01);
    } else {
        %orig;
    }
}

%end

%hook SBUISlideAppTransitionController

-(void)appTransitionView:(id)arg1 animationWillStartWithDuration:(double)arg2 afterDelay:(double)arg3 {
    %orig(arg1, arg2*0.01, arg3*0.01);
}

%end

static void CSSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[CSResources reloadSettings];
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CSSettingsChanged, CFSTR("com.matchstic.winmoswitcher/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}

