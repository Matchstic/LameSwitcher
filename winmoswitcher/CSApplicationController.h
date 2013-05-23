//
//  CSApplicationController.h
//  
//
//  Created by Kyle Howells on 21/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard/SBApplication.h>
//#import <SpringBoard/SBWorkspace.h>
#import <libactivator/libactivator.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import "CSScrollView.h"
#import <UIKit/UIKit.h>
#import "CSResources.h"
#include <dispatch/dispatch.h>
#include <dlfcn.h>

@class SpringBoard, CSApplicationController, CSApplication;

#pragma mark Defines
#define SBWPreActivateDisplayStack        [[CSApplicationController sharedController].displayStacks objectAtIndex:0]
#define SBWActiveDisplayStack             [[CSApplicationController sharedController].displayStacks objectAtIndex:1]
#define SBWSuspendingDisplayStack         [[CSApplicationController sharedController].displayStacks objectAtIndex:2]
#define SBWSuspendedEventOnlyDisplayStack [[CSApplicationController sharedController].displayStacks objectAtIndex:3]
#define SBActive                          ([SBWActiveDisplayStack topApplication] == nil)
#define SPRINGBOARD                       [CSApplicationController sharedController].springBoard
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define X_SCALE ([UIScreen mainScreen].bounds.size.width/320)
#define Y_SCALE ([UIScreen mainScreen].bounds.size.height/480)
#define SBSERVPATH "/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices"



@interface CSApplicationController : UIWindow <LAListener, UIScrollViewDelegate> {
    int result;
    UILabel *noAppsLabel;
    UILabel *timeLabel;
    UIPageControl *pageControl;
    UIButton *exitButton;

    //UIImageView *backgroundView;

    UIInterfaceOrientation currentOrientation;
    
    NSTimer *timer;
}

@property (nonatomic, readwrite) BOOL isActive;
@property (nonatomic, readwrite) BOOL isAnimating;
@property (nonatomic, retain) NSString *ignoreRelaunchID;
@property (nonatomic, readwrite) BOOL shouldAnimate;

@property (nonatomic, readwrite) BOOL pressedHome;
@property (nonatomic, readwrite) BOOL applaunching;
@property (nonatomic,readwrite) BOOL exitingAllApps;
@property (nonatomic, readwrite) BOOL isLocking;

@property (nonatomic, retain) NSMutableArray *displayStacks;
@property (nonatomic, retain) NSMutableArray *ignoredApps;
@property (nonatomic, retain) NSMutableArray *runningApps;
@property (nonatomic, retain) NSMutableArray *ignoredIDs;

@property (nonatomic, retain) CSScrollView *scrollView;

@property (nonatomic, assign) SpringBoard *springBoard;
@property (nonatomic, retain) UIImage *springBoardImage;
@property (nonatomic,retain) UIImageView* backgroundView;
@property (nonatomic, retain) UIImageView *exitBar;

@property (nonatomic, retain) UIImage *closeBox;
@property (nonatomic, retain) UIImage *statusBarDefault;

+(CSApplicationController*)sharedController;

-(void)relayoutSubviews;
-(void)setRotation:(UIInterfaceOrientation)orientation;

-(CSApplication*)csAppforApplication:(SBApplication*)app;

-(void)openApp:(NSString*)bundleId;
-(void)appLaunched:(SBApplication*)app;
-(void)appQuit:(SBApplication*)app;

-(void)deactivateGesture:(UIGestureRecognizer*)gesture;

-(void)setActive:(BOOL)active;
-(void)setActive:(BOOL)active animated:(BOOL)animated;
-(void)activateAnimated:(BOOL)animate;
-(void)deactivateAnimated:(BOOL)animate;

-(void)checkPages;

@end
