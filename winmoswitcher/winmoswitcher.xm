#import <SpringBoard/SBApplicationIcon.h>
#import <GraphicsServices/GSCapability.h>
#import <SpringBoard/SBApplication.h>
//#import <SpringBoard/SBIconBadge.h>
#import <libactivator/libactivator.h>
#import "CSApplicationController.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>


#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static NSString * const CARDSWITCHER_ID = @"com.matchstic.winmoswitcher";

/*@interface SBIcon ()
- (id)badgeNumberOrString;
@end*/

%hook SBAppSwitcherController

-(void)applicationLaunched:(SBApplication*)app{
    %orig;
    
    NSLog(@"SBAppSwitcherController: applicationLaunched");
    [[CSApplicationController sharedController] appLaunched:app];
}

-(void)applicationDied:(SBApplication*)app{
    NSLog(@"SBAppSwitcherController: applicationDied");
    [[CSApplicationController sharedController] appQuit:app];
    
    %orig;
}

%end


%hook SBApplicationIcon

-(void)launch{
    %orig;
    NSLog(@"SBApplicationIcon: launch");
    [[CSApplicationController sharedController] appLaunched:[self application]];
    NSLog(@"SBApplicationIcon: launch -> completed");
}

%end


%group OldDevices
%hook SBApplication

-(void)launch{
    %orig;
    
    NSLog(@"SBApplicationIcon: launch");
    [[CSApplicationController sharedController] appLaunched:self];
    NSLog(@"SBApplicationIcon: launch -> completed");
}

%end
%end

%hook SBApplication

-(void)exitedCommon{
    NSLog(@"SBApplication: exitedCommon");
    [[CSApplicationController sharedController] appQuit:self];
    
    %orig;
    NSLog(@"SBApplicationIcon: exitedCommon -> completed");
}

-(void)_relaunchAfterExitIfNecessary{
    NSLog(@"SBApplicationIcon: _relaunchAfterExitIfNecessary");
    if ([self.displayIdentifier isEqualToString:[CSApplicationController sharedController].ignoreRelaunchID]) {
        [[CSApplicationController sharedController].ignoreRelaunchID release], [CSApplicationController sharedController].ignoreRelaunchID = nil;
        return;
    }
    
    %orig;
    NSLog(@"SBApplicationIcon: _relaunchAfterExitIfNecessary -> completed");
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
    [[CSApplicationController sharedController] setActive:NO animated:NO];
    
    %orig;
}

%end


%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application{
    %orig;

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

static void CSSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[CSResources reloadSettings];
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CSSettingsChanged, CFSTR("com.matchstic.winmoswitcher/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}

