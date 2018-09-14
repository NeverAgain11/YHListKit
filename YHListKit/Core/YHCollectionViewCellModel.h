//
//  YHCollectionViewCellModel.h
//  YHOUSE
//
//  Created by ShannonChen on 2017/11/28.
//  Copyright © 2017年 YHouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YHCollectionViewProtocols.h"
NS_ASSUME_NONNULL_BEGIN
/**
 通用 cell model
 */

typedef void(^YHSelectBlock)(UICollectionView *collectionView, NSIndexPath *indexPath);
typedef void(^YHDequeueBlock)(UICollectionViewCell *cell, NSIndexPath *indexPath);

@interface YHCollectionViewCellModel : NSObject

@property (strong, nonatomic, nullable) Class cellClass;   // class 和 nibName 两个属性必须选择设置其中一个
@property (copy, nonatomic, nullable) NSString *nibName;

@property (assign, nonatomic) CGFloat cellHeight;
@property (assign, nonatomic) CGFloat cellWidth;  // 可选字段，默认是 container 的宽度
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (assign, nonatomic) NSInteger numberOfItemsInSection;
@property (strong, nonatomic) id dataModel;

@property (nonatomic, copy) YHSelectBlock didSelectItem;
@property (nonatomic, copy) YHDequeueBlock didDequeueCell;

- (void)collectionViewDidSelectItem:(UICollectionView *)collectionView;

@end

NS_ASSUME_NONNULL_END
