//
//  YHCollectionViewCell.h
//  YHOUSE
//
//  Created by ShannonChen on 2017/11/28.
//  Copyright © 2017年 YHouse. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YHCollectionViewCellModel, YHCollectionViewSectionModel;
NS_ASSUME_NONNULL_BEGIN
/**
 通用的 cell 协议
 */
@protocol YHCollectionViewCell <NSObject>
    
@required
@property (strong, nonatomic, nullable) YHCollectionViewCellModel *cellModel;
    
@optional
+ (CGFloat)cellHeightWithModel:(YHCollectionViewCellModel *)model;
+ (CGFloat)cellWidthWithModel:(YHCollectionViewCellModel *)model;
    
    
    @end


/**
 通用 section header / footer 协议
 */
@protocol YHCollectionViewSectionHeaderFooter <NSObject>

@optional
@property (strong, nonatomic, nullable) YHCollectionViewSectionModel *sectionModel;
+ (CGFloat)heightWithModel:(YHCollectionViewSectionModel *)model;
+ (CGFloat)widthWithModel:(YHCollectionViewSectionModel *)model;
    
@end
NS_ASSUME_NONNULL_END
