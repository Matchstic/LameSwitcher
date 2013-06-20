//
//  Overview.m
//  winmoswitcher
//
//  Created by Matt Clarke on 30/05/2013.
//
//

#import <QuartzCore/QuartzCore.h>
#import <SpringBoard/SpringBoard.h>
#import <UIKit/UICollectionView.h>
#import <objc/runtime.h>
#import "Overview.h"
#import "CSApplicationController.h"
#import "CSApplication.h"
#import "stackBlur.h"

#define BUNDLE @"/Library/Application Support/WinMoSwitcher/WinMoSwitcher.bundle"

static UIImage *deleteButtonImg;

@implementation OverviewController

@synthesize backgroundView;
@synthesize blur;

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[CSApplicationController sharedController].runningApps count];
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OverviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"OverviewCell" forIndexPath:indexPath];
    SBApplication *app = [[CSApplicationController sharedController].runningApps objectAtIndex:indexPath.item];
    [cell.contentView addSubview:[self snapshotForApplication:app]];
    
    /*[cell.deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activateDeletionMode:)];
    longPress.delegate = self;
    [cell addGestureRecognizer:longPress];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endDeletionMode:)];
    tap.delegate = self;
    [cell addGestureRecognizer:tap];*/
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cell #%d was selected", indexPath.row);
    
    // Our launching code goes here!
    SBApplication *app = [[CSApplicationController sharedController].runningApps objectAtIndex:indexPath.item];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [CSApplicationController sharedController].scrollView.userInteractionEnabled = NO;
    [CSApplicationController sharedController].applaunching = YES;
    
    // Here we'll do something with the close button?
    //[UIView animateWithDuration:0.1 animations:^{
        //self.closeBox.alpha = 0;
    //}completion:^(BOOL finished){}];
    
    SBApplication *runningApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    
    if (runningApp != nil) {
        // An app is already open, so use the switcher animation, but first check if this is the same app.
        if (![[runningApp bundleIdentifier] isEqualToString:[app bundleIdentifier]]) {
            [CSApplicationController sharedController].shouldAnimate = YES;
            [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:app];
        }
    } else {
        // Else we are on SpringBoard
        if ([[app displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
            // Close the topmost app if we're opening SpringBoard
            [(SpringBoard *)[UIApplication sharedApplication] quitTopApplication:nil];
        } else {
            [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:app];
        }
    }
    
    // Adjust x + y origin as appropriate
    CGRect snapshotOrigFrame = cell.frame;
    snapshotOrigFrame.origin.y += ([UIApplication sharedApplication].statusBarFrame.size.height)+(SCREEN_HEIGHT*0.05);
    snapshotOrigFrame.origin.x += (SCREEN_WIDTH*0.05);
    
    UIView *snapshotAnim = [[UIView alloc] initWithFrame:snapshotOrigFrame];
    [snapshotAnim addSubview:[self snapshotForApplication:app]];
    [[CSApplicationController sharedController] addSubview:snapshotAnim];
    
    // Launch animation
    [UIView animateWithDuration:0.6 animations:^{
        snapshotAnim.frame = [UIScreen mainScreen].bounds;
        for (UIImageView *view in snapshotAnim.subviews) {
            view.frame = snapshotAnim.frame;
        }
    } completion:^(BOOL finished){
        // Now, remove things from the superview
        [snapshotAnim removeFromSuperview];
        [[CSApplicationController sharedController] removeStuffFromView];
        [[CSApplicationController sharedController] removeOverview];
        
        [[CSApplicationController sharedController] setActive:NO animated:NO];
        
        [CSResources reset];
    }];
    
    // Fade out the time label
    [UIView animateWithDuration:0.4 animations:^{
        [CSApplicationController sharedController].timeLabel.alpha = 0.0f;
    }];
}

-(UIImageView *)snapshotForApplication:(SBApplication *)app {
    UIImageView *snapshot = [[[UIImageView alloc] init] autorelease];
    
    snapshot.backgroundColor = [UIColor clearColor];
    snapshot.frame = CGRectMake(0, 0, (SCREEN_WIDTH*0.27), (SCREEN_HEIGHT*0.27));
    snapshot.userInteractionEnabled = YES;
    snapshot.layer.masksToBounds = YES;
    snapshot.layer.cornerRadius = [CSResources cornerRadius];
    snapshot.layer.borderWidth = 0;
    snapshot.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
    snapshot.image = [CSResources cachedScreenShot:app];
   
    return snapshot;
}

#pragma mark - delete for button

- (void)delete:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(OverviewCell *)sender.superview.superview];
    [[CSApplicationController sharedController].runningApps removeObjectAtIndex:indexPath.item];
    [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (isDeletionModeActive) return NO;
    else return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
    if (indexPath && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        return NO;
    }
    return YES;
}

- (void)activateDeletionMode:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gr locationInView:self.collectionView]];
        if (indexPath) {
            isDeletionModeActive = YES;
            OverviewFlowLayout *layout = (OverviewFlowLayout *)self.collectionView.collectionViewLayout;
            [layout invalidateLayout];
        }
    }
}

- (void)endDeletionMode:(UITapGestureRecognizer *)gr {
    if (isDeletionModeActive) {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gr locationInView:self.collectionView]];
        if (!indexPath) {
            isDeletionModeActive = NO;
            OverviewFlowLayout *layout = (OverviewFlowLayout *)self.collectionView.collectionViewLayout;
            [layout invalidateLayout];
        }
    }
}

- (BOOL)isDeletionModeActiveForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout {
    return isDeletionModeActive;
}

@end

@implementation OverviewFlowLayout

/*-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize val = 
    return val;
}*/

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    //                      top left bottom right
    return UIEdgeInsetsMake(50, 20, (SCREEN_HEIGHT*0.05), 20);
}

- (BOOL)isDeletionModeOn {
    if ([[self.collectionView.delegate class] conformsToProtocol:@protocol(OverviewLayoutDelegate)])
    {
        return [(id)self.collectionView.delegate isDeletionModeActiveForCollectionView:self.collectionView layout:self];
        
    }
    return NO;
    
}

// INSERT ATTRIBUTES SNIPPET HERE

+ (Class)layoutAttributesClass {
    return [OverviewLayoutAttributes class];
}

- (OverviewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    OverviewLayoutAttributes *attributes = (OverviewLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    if ([self isDeletionModeOn])
        attributes.deleteButtonHidden = NO;
    else
        attributes.deleteButtonHidden = YES;
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributesArrayInRect = [super layoutAttributesForElementsInRect:rect];
    
    for (OverviewLayoutAttributes *attribs in attributesArrayInRect)
    {
        if ([self isDeletionModeOn]) attribs.deleteButtonHidden = NO;
        else attribs.deleteButtonHidden = YES;
    }
    return attributesArrayInRect;
}

@end

@implementation OverviewLayoutAttributes

-(id)copyWithZone:(NSZone *)zone {
    OverviewLayoutAttributes *attributes = [super copyWithZone:zone];
    attributes.deleteButtonHidden = _deleteButtonHidden;
    return attributes;
}

@end

@implementation OverviewCell

@synthesize deleteButton;

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        // Get the Bundle
        NSBundle *bundle = [[NSBundle alloc] initWithPath:BUNDLE];
        
        // Exit button image
        if (!deleteButtonImg) {
            deleteButtonImg = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"Close" ofType:@"png"]];
        }
        
        self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width/16, frame.size.width/16, frame.size.width/4, frame.size.width/4)];

        [self.deleteButton setImage:deleteButtonImg forState:UIControlStateNormal];
        
        [self.contentView addSubview:self.deleteButton];
        
    }
    return self;
}

-(void)applyLayoutAttributes:(OverviewLayoutAttributes *)layoutAttributes {
    if (layoutAttributes.isDeleteButtonHidden) {
        self.deleteButton.layer.opacity = 0.0;
    } else {
        self.deleteButton.layer.opacity = 1.0;
        
    }
}

@end