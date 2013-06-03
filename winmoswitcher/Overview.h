//
//  Overview.h
//  winmoswitcher
//
//  Created by Matt Clarke on 30/05/2013.
//
//

#import <UIKit/UIKit.h>

@interface OverviewController : UICollectionViewController

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface OverviewFlowLayout : UICollectionViewFlowLayout

@end

@interface OverviewCell : UICollectionViewCell

-(id)initWithFrame:(CGRect)frame;
@end