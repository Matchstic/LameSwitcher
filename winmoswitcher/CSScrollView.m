//
//  CSScrollView.m
//
//
//  Created by Kyle Howells on 29/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import "CSScrollView.h"
#import "CSApplicationController.h"

@implementation CSScrollView

-(BOOL)viewIsVisible:(UIView*)view{
    if ([CSApplicationController sharedController].applaunching || [CSApplicationController sharedController].overviewAnim ) {
        // Either in app launch anim, or overview anim
        return YES;
    } else {
        CGRect visibleRect;
        visibleRect.origin = self.contentOffset;
        visibleRect.size = self.bounds.size;
        visibleRect.origin.x -= 50 + (SCREEN_WIDTH*0.1);
        visibleRect.size.width += 100 + (SCREEN_WIDTH*0.15);

        return CGRectIntersectsRect(visibleRect, view.frame);
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint parentLocation = [self convertPoint:point toView:self.superview];
    /*CGRect responseRect = self.frame;
    responseRect.origin.x -= responseInsets.left;
    responseRect.origin.y -= responseInsets.top;
    responseRect.size.width += (responseInsets.left + responseInsets.right);
    responseRect.size.height += (responseInsets.top + responseInsets.bottom);
    return CGRectContainsPoint(responseRect, parentLocation);*/

    return [self.superview pointInside:parentLocation withEvent:event];
}

/*float difference;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint contentTouchPoint = [[touches anyObject] locationInView:[UIApplication sharedApplication].keyWindow];
    if ([[event allTouches] count] > 1) {
        difference = contentTouchPoint.x;
        NSLog(@"difference: %f", difference);
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGPoint pointInView = [[touches anyObject] locationInView:[UIApplication sharedApplication].keyWindow];
    
    float xTarget = self.frame.origin.x + (pointInView.x - difference);
    //if(xTarget > self.frame.size.width)
        //xTarget = self.frame.size.width;
    //else if( xTarget < 0)
        //xTarget = 0;
    
    NSLog(@"xTarget: %f", xTarget);
    NSLog(@"pointInView: %f", pointInView.x);
    
    [UIView animateWithDuration:0.25 animations:^{
        [self setFrame:CGRectMake(xTarget, self.frame.origin.y, self.frame.size.width, self.frame.size.height)];
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGPoint endPoint = [[touches anyObject] locationInView:[UIApplication sharedApplication].keyWindow];
    float xTarget;
    BOOL willShowOverview;
    if(endPoint.x < SCREEN_WIDTH*0.3) {
        xTarget = -SCREEN_WIDTH*[[CSApplicationController sharedController].runningApps count];
        willShowOverview = YES;
    } else {
        xTarget = ((SCREEN_WIDTH/2)-((SCREEN_WIDTH*0.625)/2))-((([UIScreen mainScreen].bounds.size.width-(40*2))*0.875-(SCREEN_WIDTH*0.625))/2);
    }
    
    NSLog(@"xTarget: %f", xTarget);
    NSLog(@"endPoint: %f", endPoint.x);
    
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = CGRectMake(xTarget, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL finished){
        if (willShowOverview) {
            [[CSApplicationController sharedController] showOverview];
            for (UIView *view in self.subviews) {
                [view removeFromSuperview];
            }
        }
        CGRect scrollViewFrame = [UIScreen mainScreen].bounds;
        scrollViewFrame.origin.x = ((SCREEN_WIDTH/2)-((SCREEN_WIDTH*0.625)/2))-((scrollViewFrame.size.width-(SCREEN_WIDTH*0.625))/2);
        self.frame = scrollViewFrame;
    }];
}*/

@end
