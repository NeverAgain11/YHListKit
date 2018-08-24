//
//  YHCollectionViewSectionModel.h
//  YHOUSE
//
//  Created by ShannonChen on 2017/11/28.
//  Copyright © 2017年 YHouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YHCollectionViewCellModel.h"

NS_ASSUME_NONNULL_BEGIN
/**
 通用 section model
 */
@interface YHCollectionViewSectionModel : NSObject
    
@property (strong, nonatomic, nullable) Class headerClass;     // class 和 nibName 两个属性必须设置一个
@property (copy, nonatomic, nullable) NSString *headerNibName;
@property (copy, nonatomic, nullable) NSString *headerTitle;
@property (assign, nonatomic) CGFloat headerTitleOriginY; // 标题原点 Y
@property (copy, nonatomic, nullable) NSString *headerSubtitle;
@property (assign, nonatomic) CGFloat headerHeight;
@property (assign, nonatomic) CGFloat headerWidth;
@property (strong, nonatomic, nullable) id headerModel;  // 可选字段
    
@property (assign, nonatomic) NSInteger section;
@property (assign, nonatomic) NSInteger numberOfSectionsInCollectionView;
@property (copy, nonatomic) NSString *sectionIdentifier; // 用于标识 section 的唯一性，在需要时可以直接根据该参数获取到所需的 section model，可选字段
    
@property (strong, nonatomic) NSArray <YHCollectionViewCellModel *> *cellModels;
    
@property (copy, nonatomic, nullable) NSString *footerTitle;
@property (assign, nonatomic) CGFloat footerWidth;
@property (assign, nonatomic) CGFloat footerHeight;
@property (strong, nonatomic, nullable) Class footerClass;      // class 和 nibName 两个属性必须设置一个
@property (copy, nonatomic, nullable) NSString *footerNibName;
    
@property (nonatomic, assign) CGFloat minimumLineSpacing;
@property (nonatomic, assign) CGFloat minimumInteritemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInsets;
    
@end

NS_ASSUME_NONNULL_END
