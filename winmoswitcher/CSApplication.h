//
//  PSAppCard.h
//  
//
//  Created by Kyle Howells on 06/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SBApplication, SBIconBadge;

@interface CSApplication : UIView

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIImageView *icon;
@property (nonatomic, retain) UIButton *closeBox;
@property (nonatomic, retain) UIImageView *badge;
@property (nonatomic, retain) UIImageView *snapshot;
@property (nonatomic, retain) SBApplication *application;
@property (nonatomic, retain) UIImage *appImage;

+(CSApplication*)sharedController;

-(id)init;
-(void)loadImages;
-(void)reset;
-(id)initWithApplication:(SBApplication*)application;
//-(void)layoutIcon;
-(void)launch;
-(void)exit;
-(void)exitAllApps;
-(void)quitPressed;
-(void)launchGesture:(UIGestureRecognizer*)gesture;
-(void)closeUpGesture:(UIGestureRecognizer*)gesture;
-(void)closeDownGesture:(UIGestureRecognizer*)gesture;

@end
