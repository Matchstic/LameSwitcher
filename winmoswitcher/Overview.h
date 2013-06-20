//
//  Overview.h
//  winmoswitcher
//
//  Created by Matt Clarke on 30/05/2013.
//
//

#import <UIKit/UIKit.h>

@protocol OverviewLayoutDelegate <UICollectionViewDelegateFlowLayout>

@required

- (BOOL) isDeletionModeActiveForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout;

@end

@interface OverviewController : UICollectionViewController<OverviewLayoutDelegate, UIGestureRecognizerDelegate>
{
    BOOL isDeletionModeActive;
}

@property (nonatomic,retain) UIImageView* backgroundView;
@property (nonatomic, retain) UIImageView *blur;

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface OverviewFlowLayout : UICollectionViewFlowLayout

@end

@interface OverviewLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, getter = isDeleteButtonHidden) BOOL deleteButtonHidden;

@end

@interface OverviewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *deleteButton;

-(id)initWithFrame:(CGRect)frame;
@end