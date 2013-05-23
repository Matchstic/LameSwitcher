#line 1 "/Users/Matt/iOS/Projects/winmoswitcher/winmoswitcher/winmoswitcher.xm"
#import <SpringBoard/SBApplicationIcon.h>
#import <GraphicsServices/GSCapability.h>
#import <SpringBoard/SBApplication.h>

#import <libactivator/libactivator.h>
#import "CSApplicationController.h"
#import "CSResources.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <Strife/SLockWindow.h>
#import <Strife/SRootScrollView.h>



#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static NSString * const CARDSWITCHER_ID = @"com.matchstic.winmoswitcher";





#include <logos/logos.h>
#include <substrate.h>
@class SBApplication; @class SBApplicationIcon; @class SBAwayController; @class SBDisplayStack; @class SpringBoard; @class SBAppSwitcherController; 
static void (*_logos_orig$_ungrouped$SBAppSwitcherController$applicationLaunched$)(SBAppSwitcherController*, SEL, SBApplication*); static void _logos_method$_ungrouped$SBAppSwitcherController$applicationLaunched$(SBAppSwitcherController*, SEL, SBApplication*); static void (*_logos_orig$_ungrouped$SBAppSwitcherController$applicationDied$)(SBAppSwitcherController*, SEL, SBApplication*); static void _logos_method$_ungrouped$SBAppSwitcherController$applicationDied$(SBAppSwitcherController*, SEL, SBApplication*); static void (*_logos_orig$_ungrouped$SBApplicationIcon$launch)(SBApplicationIcon*, SEL); static void _logos_method$_ungrouped$SBApplicationIcon$launch(SBApplicationIcon*, SEL); static void (*_logos_orig$_ungrouped$SBApplication$exitedCommon)(SBApplication*, SEL); static void _logos_method$_ungrouped$SBApplication$exitedCommon(SBApplication*, SEL); static void (*_logos_orig$_ungrouped$SBApplication$_relaunchAfterExitIfNecessary)(SBApplication*, SEL); static void _logos_method$_ungrouped$SBApplication$_relaunchAfterExitIfNecessary(SBApplication*, SEL); static id (*_logos_orig$_ungrouped$SBDisplayStack$init)(SBDisplayStack*, SEL); static id _logos_method$_ungrouped$SBDisplayStack$init(SBDisplayStack*, SEL); static void (*_logos_orig$_ungrouped$SBDisplayStack$dealloc)(SBDisplayStack*, SEL); static void _logos_method$_ungrouped$SBDisplayStack$dealloc(SBDisplayStack*, SEL); static void (*_logos_orig$_ungrouped$SBAwayController$lock)(SBAwayController*, SEL); static void _logos_method$_ungrouped$SBAwayController$lock(SBAwayController*, SEL); static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(SpringBoard*, SEL, UIApplication *); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(SpringBoard*, SEL, UIApplication *); 

#line 27 "/Users/Matt/iOS/Projects/winmoswitcher/winmoswitcher/winmoswitcher.xm"


static void _logos_method$_ungrouped$SBAppSwitcherController$applicationLaunched$(SBAppSwitcherController* self, SEL _cmd, SBApplication* app){
    _logos_orig$_ungrouped$SBAppSwitcherController$applicationLaunched$(self, _cmd, app);
    
    NSLog(@"SBAppSwitcherController: applicationLaunched");
    [[CSApplicationController sharedController] appLaunched:app];
}

static void _logos_method$_ungrouped$SBAppSwitcherController$applicationDied$(SBAppSwitcherController* self, SEL _cmd, SBApplication* app){
    NSLog(@"SBAppSwitcherController: applicationDied");
    [[CSApplicationController sharedController] appQuit:app];
    
    _logos_orig$_ungrouped$SBAppSwitcherController$applicationDied$(self, _cmd, app);
}






static void _logos_method$_ungrouped$SBApplicationIcon$launch(SBApplicationIcon* self, SEL _cmd){
    _logos_orig$_ungrouped$SBApplicationIcon$launch(self, _cmd);
    [[CSApplicationController sharedController] appLaunched:[self application]];
}




static void (*_logos_orig$OldDevices$SBApplication$launch)(SBApplication*, SEL); static void _logos_method$OldDevices$SBApplication$launch(SBApplication*, SEL); 


static void _logos_method$OldDevices$SBApplication$launch(SBApplication* self, SEL _cmd){
    _logos_orig$OldDevices$SBApplication$launch(self, _cmd);
    
    [[CSApplicationController sharedController] appLaunched:self];
}






static void _logos_method$_ungrouped$SBApplication$exitedCommon(SBApplication* self, SEL _cmd){
    [[CSApplicationController sharedController] appQuit:self];
    
    _logos_orig$_ungrouped$SBApplication$exitedCommon(self, _cmd);
}

static void _logos_method$_ungrouped$SBApplication$_relaunchAfterExitIfNecessary(SBApplication* self, SEL _cmd){
    if ([self.displayIdentifier isEqualToString:[CSApplicationController sharedController].ignoreRelaunchID]) {
        [[CSApplicationController sharedController].ignoreRelaunchID release], [CSApplicationController sharedController].ignoreRelaunchID = nil;
        return;
    }
    
    _logos_orig$_ungrouped$SBApplication$_relaunchAfterExitIfNecessary(self, _cmd);
}





static id _logos_method$_ungrouped$SBDisplayStack$init(SBDisplayStack* self, SEL _cmd){
	if ((self = _logos_orig$_ungrouped$SBDisplayStack$init(self, _cmd))) {
        NSLog(@"SBDisplayStack: init");
        [[CSApplicationController sharedController].displayStacks addObject:self];
	}
	return self;
}

static void _logos_method$_ungrouped$SBDisplayStack$dealloc(SBDisplayStack* self, SEL _cmd){
    NSLog(@"SBDisplayStack: dealloc");
	[[CSApplicationController sharedController].displayStacks removeObject:self];
    
	_logos_orig$_ungrouped$SBDisplayStack$dealloc(self, _cmd);
}







































static void _logos_method$_ungrouped$SBAwayController$lock(SBAwayController* self, SEL _cmd){
    NSLog(@"SBAwayController: lock");
    [CSApplicationController sharedController].isLocking = YES;
    [[CSApplicationController sharedController] setActive:NO animated:NO];
    
    _logos_orig$_ungrouped$SBAwayController$lock(self, _cmd);
}






static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(SpringBoard* self, SEL _cmd, UIApplication * application){
    _logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);

    
    
    [CSApplicationController sharedController].springBoard = self;

    if (![[LAActivator sharedInstance] hasSeenListenerWithName:CARDSWITCHER_ID])
        [[LAActivator sharedInstance] assignEvent:[LAEvent eventWithName:LAEventNameMenuPressDouble] toListenerWithName:CARDSWITCHER_ID];

    [[LAActivator sharedInstance] registerListener:[CSApplicationController sharedController] forName:CARDSWITCHER_ID];


    if (!GSSystemHasCapability(kGSMultitaskingCapability)) {
        {Class _logos_class$OldDevices$SBApplication = objc_getClass("SBApplication"); MSHookMessageEx(_logos_class$OldDevices$SBApplication, @selector(launch), (IMP)&_logos_method$OldDevices$SBApplication$launch, (IMP*)&_logos_orig$OldDevices$SBApplication$launch);}
    }
}
































































































static void CSSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[CSResources reloadSettings];
}

static __attribute__((constructor)) void _logosLocalCtor_7a614fd0()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{Class _logos_class$_ungrouped$SBAppSwitcherController = objc_getClass("SBAppSwitcherController"); MSHookMessageEx(_logos_class$_ungrouped$SBAppSwitcherController, @selector(applicationLaunched:), (IMP)&_logos_method$_ungrouped$SBAppSwitcherController$applicationLaunched$, (IMP*)&_logos_orig$_ungrouped$SBAppSwitcherController$applicationLaunched$);MSHookMessageEx(_logos_class$_ungrouped$SBAppSwitcherController, @selector(applicationDied:), (IMP)&_logos_method$_ungrouped$SBAppSwitcherController$applicationDied$, (IMP*)&_logos_orig$_ungrouped$SBAppSwitcherController$applicationDied$);Class _logos_class$_ungrouped$SBApplicationIcon = objc_getClass("SBApplicationIcon"); MSHookMessageEx(_logos_class$_ungrouped$SBApplicationIcon, @selector(launch), (IMP)&_logos_method$_ungrouped$SBApplicationIcon$launch, (IMP*)&_logos_orig$_ungrouped$SBApplicationIcon$launch);Class _logos_class$_ungrouped$SBApplication = objc_getClass("SBApplication"); MSHookMessageEx(_logos_class$_ungrouped$SBApplication, @selector(exitedCommon), (IMP)&_logos_method$_ungrouped$SBApplication$exitedCommon, (IMP*)&_logos_orig$_ungrouped$SBApplication$exitedCommon);MSHookMessageEx(_logos_class$_ungrouped$SBApplication, @selector(_relaunchAfterExitIfNecessary), (IMP)&_logos_method$_ungrouped$SBApplication$_relaunchAfterExitIfNecessary, (IMP*)&_logos_orig$_ungrouped$SBApplication$_relaunchAfterExitIfNecessary);Class _logos_class$_ungrouped$SBDisplayStack = objc_getClass("SBDisplayStack"); MSHookMessageEx(_logos_class$_ungrouped$SBDisplayStack, @selector(init), (IMP)&_logos_method$_ungrouped$SBDisplayStack$init, (IMP*)&_logos_orig$_ungrouped$SBDisplayStack$init);MSHookMessageEx(_logos_class$_ungrouped$SBDisplayStack, @selector(dealloc), (IMP)&_logos_method$_ungrouped$SBDisplayStack$dealloc, (IMP*)&_logos_orig$_ungrouped$SBDisplayStack$dealloc);Class _logos_class$_ungrouped$SBAwayController = objc_getClass("SBAwayController"); MSHookMessageEx(_logos_class$_ungrouped$SBAwayController, @selector(lock), (IMP)&_logos_method$_ungrouped$SBAwayController$lock, (IMP*)&_logos_orig$_ungrouped$SBAwayController$lock);Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);}
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CSSettingsChanged, CFSTR("com.matchstic.winmoswitcher/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}

