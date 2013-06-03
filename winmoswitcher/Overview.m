//
//  Overview.m
//  winmoswitcher
//
//  Created by Matt Clarke on 30/05/2013.
//
//

#import "Overview.h"
#import "CSApplicationController.h"
#import "CSApplication.h"

@implementation OverviewController

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"OverviewController collectionView:numberOfItemsInSection:");
    return [[CSApplicationController sharedController].runningApps count];
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"OverviewController collectionView:cellForItemAtIndexPath:");
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"OverviewCell" forIndexPath:indexPath];
    SBApplication *app = [[CSApplicationController sharedController].runningApps objectAtIndex:indexPath.item];
    // Need to correctly adjust size of snapshots etc
    NSLog(@"init'd with application");
    [cell.contentView addSubview:[self snapshotForApplication:app]];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cell #%d was selected", indexPath.row);
    // Our launching code will go here!
}

-(UIImageView *)snapshotForApplication:(SBApplication *)app {
    UIImageView *snapshot = nil;
    
    snapshot = [[[UIImageView alloc] init] autorelease];
    snapshot.backgroundColor = [UIColor clearColor];
    snapshot.frame = CGRectMake(0, (SCREEN_HEIGHT*0.16), (SCREEN_WIDTH*0.3), (SCREEN_HEIGHT*0.3));
    snapshot.userInteractionEnabled = YES;
    snapshot.layer.masksToBounds = YES;
    snapshot.layer.cornerRadius = [CSResources cornerRadius];
    snapshot.layer.borderWidth = 0;
    snapshot.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
    snapshot.image = [CSResources cachedScreenShot:app];
    
    return snapshot;
}

@end

@implementation OverviewFlowLayout

/*-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize val = 
    return val;
}*/

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // Use this to configure the gaps between the snapshots?
    return UIEdgeInsetsMake(50, 20, 50, 20);
}

@end

@implementation OverviewCell

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
    }
    return self;
}

@end