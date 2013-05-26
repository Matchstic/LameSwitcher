//
//  winmoswitcher_prefsController.h
//  winmoswitcher-prefs
//
//  Created by Matt Clarke on 25/05/2013.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

@interface winmoswitcher_prefsController : PSListController
{
}

-(void)viewDidAppear:(BOOL)view;
-(NSString *)getBackgroundValue;
@end

@interface backgroundController : PSListController
//-(void)viewWillAppear:(BOOL)view;
//-(void)viewDidUnload;
-(void)setBackgroundValue:(id)value forSpecifier:(id)specifier;
-(int)getBackgroundValue;
@end