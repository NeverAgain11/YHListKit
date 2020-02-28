//
//  YHCollectionViewAdapter.m
//  YHOUSE
//
//  Created by ShannonChen on 2017/11/28.
//  Copyright © 2017年 YHouse. All rights reserved.
//

#import "YHCollectionViewAdapter.h"
#import "YHCollectionViewCellModel.h"
#import "YHCollectionViewSectionModel.h"
#import "YHCollectionViewProtocols.h"

#import "UIDevice+YHouse.h"
#import "MessageInterceptor.h"

/// Generate a string representation of a reusable view class when registering with a UICollectionView.
NS_INLINE NSString *YHReusableViewIdentifier(Class viewClass, NSString * _Nullable nibName, NSString * _Nullable kind) {
    return [NSString stringWithFormat:@"%@%@%@", kind ?: @"", nibName ?: @"", NSStringFromClass(viewClass)];
}

@interface YHCollectionViewAdapter ()

// https://stackoverflow.com/a/13410537
@property (strong, nonatomic) NSMutableDictionary <NSNumber *, UICollectionReusableView *> *sectionHeaderMap;
@property (nonatomic, strong) NSMutableSet<Class> *registeredCellClasses;
@property (nonatomic, strong) NSMutableSet<NSString *> *registeredCellNibNames;
@property (nonatomic, strong) NSMutableSet<NSString *> *registeredSupplementaryViewIdentifiers;
@property (nonatomic, strong) NSMutableSet<NSString *> *registeredSupplementaryViewNibNames;


@property (strong, nonatomic) MessageInterceptor *delegateInterceptor;

@end

@implementation YHCollectionViewAdapter


- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    
    collectionView.delegate = (id <UICollectionViewDelegate>)self.delegateInterceptor;
    collectionView.dataSource = self;
}

- (void)setCollectionViewDelegate:(id<UICollectionViewDelegate>)collectionViewDelegate {
    _collectionViewDelegate = collectionViewDelegate;
    
    self.delegateInterceptor.receiver = collectionViewDelegate;
}

#pragma mark - Public
- (YHCollectionViewSectionModel *)collectionView:(UICollectionView *)collectionView viewModelForSection:(NSInteger)section {
    if (self.sectionModels.count > section) {
        return self.sectionModels[section];
    }
    
    return nil;
}

- (YHCollectionViewCellModel *)collectionView:(UICollectionView *)collectionView cellModelForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.sectionModels.count > indexPath.section &&
        self.sectionModels[indexPath.section].cellModels.count > indexPath.row) {
        
        return self.sectionModels[indexPath.section].cellModels[indexPath.row];
    }
    
    return nil;
}

// https://stackoverflow.com/a/13410537
- (UICollectionReusableView *)sectionHeaderForSection:(NSInteger)section {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        return [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
    } else {
        return self.sectionHeaderMap[@(section)];
    }
}

#pragma mark -  <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    self.collectionView = collectionView;
    
    [self p_setupCellCountAndSectionCountForModels];
    
    return self.sectionModels.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.sectionModels.count > section) {
        return self.sectionModels[section].cellModels.count;
    }
    return 0;
}

// cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    YHCollectionViewCellModel *cellModel = [self collectionView:collectionView cellModelForItemAtIndexPath:indexPath];
    Class cellClass = cellModel.cellClass;
    NSString *nibName = cellModel.nibName;
    
    if (cellClass || nibName) {
        
        NSString *identifier = YHReusableViewIdentifier(cellClass, nibName, nil);
        if (nibName) {
            if (![self.registeredCellNibNames containsObject:nibName]) {
                [collectionView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellWithReuseIdentifier:identifier];
                [self.registeredCellNibNames addObject:nibName];
            }
        } else {
            if (![self.registeredCellClasses containsObject:cellClass]) {
                [collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
                [self.registeredCellClasses addObject:cellClass];
            }
        }
        
        UICollectionViewCell <YHCollectionViewCell> *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        
        if ([cell conformsToProtocol:@protocol(YHCollectionViewCell)]) {
            cell.cellModel = cellModel;
        }
        
        if (cell.cellModel.didDequeueCell) {
            cell.cellModel.didDequeueCell(cell, indexPath);
        }
        
        if ([self.delegate respondsToSelector:@selector(collectionViewAdapter:didDequeueCell:atIndexPath:)]) {
            [self.delegate collectionViewAdapter:self didDequeueCell:cell atIndexPath:indexPath];
        }
        
        return cell;
    }
    
    return [[UICollectionViewCell alloc] init];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell conformsToProtocol:@protocol(YHCollectionViewCell)]) {
        UICollectionViewCell <YHCollectionViewCell> *yhCell = (UICollectionViewCell <YHCollectionViewCell> *) cell;
        [yhCell willDisplay];
        
        if (yhCell.cellModel.willDisplayCell) {
            yhCell.cellModel.willDisplayCell(cell, indexPath);
        }
    }
    
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [self.collectionViewDelegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

// section header & footer
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    YHCollectionViewSectionModel *model = [self collectionView:collectionView viewModelForSection:indexPath.section];
    Class viewClass = (kind == UICollectionElementKindSectionHeader) ? model.headerClass : model.footerClass;
    NSString *nibName = (kind == UICollectionElementKindSectionHeader) ? model.headerNibName : model.footerNibName;
    
    NSString *identifier = YHReusableViewIdentifier(viewClass, nibName, kind);
    
    if (nibName) {
        if (![self.registeredSupplementaryViewNibNames containsObject:identifier]) {
            [self.registeredSupplementaryViewNibNames addObject:identifier];
            [collectionView registerNib:[UINib nibWithNibName:nibName bundle:nil] forSupplementaryViewOfKind:kind withReuseIdentifier:identifier];
        }
    } else {
        if (![self.registeredSupplementaryViewIdentifiers containsObject:identifier]) {
            [self.registeredSupplementaryViewIdentifiers addObject:identifier];
            [collectionView registerClass:viewClass forSupplementaryViewOfKind:kind withReuseIdentifier:identifier];
        }
    }
    
    if (viewClass || nibName) {
        UICollectionReusableView <YHCollectionViewSectionHeaderFooter> *headerFooter = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
        
        if (kind == UICollectionElementKindSectionHeader && headerFooter) {
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0") == NO) {
                [self.sectionHeaderMap setObject:headerFooter forKey:@(indexPath.section)];
            }
        }
        
        if ([headerFooter respondsToSelector:@selector(setSectionModel:)]) {
            [headerFooter setSectionModel:model];
        }
        
        if ([self.delegate respondsToSelector:@selector(collectionViewAdapter:didDequeueSupplementaryView:ofKind:atIndexPath:)]) {
            [self.delegate collectionViewAdapter:self didDequeueSupplementaryView:headerFooter ofKind:kind atIndexPath:indexPath];
        }
        
        return headerFooter;
    }
    
    return [[UICollectionReusableView alloc] init];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)]) {
        return [self.delegate collectionView:collectionView canMoveItemAtIndexPath:indexPath];
    }
    return false;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toIndexPath:)]) {
        [self.delegate collectionView:collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)originalIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:)]) {
        return [self.delegate collectionView:collectionView targetIndexPathForMoveFromItemAtIndexPath:originalIndexPath toProposedIndexPath:proposedIndexPath];
    }
    return proposedIndexPath;
}

#pragma mark - <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
    // https://stackoverflow.com/a/46930410
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_iOS_11_0) {
        if ([collectionView.collectionViewLayout isMemberOfClass:[UICollectionViewFlowLayout class]] && [elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            view.layer.zPosition = 0;
        }
    }
    
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)]) {
        [self.collectionViewDelegate collectionView:collectionView willDisplaySupplementaryView:view forElementKind:elementKind atIndexPath:indexPath];
    }
}

#pragma mark - <UICollectionViewDelegateFlowLayout>
// 计算 cell 尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    YHCollectionViewCellModel *cellModel = [self collectionView:collectionView cellModelForItemAtIndexPath:indexPath];
    Class cellClass = cellModel.cellClass;
    
    if (cellModel.cellHeight == CGFLOAT_MAX) { // 高度没有缓存
        
        if ([cellClass respondsToSelector:@selector(cellHeightWithModel:)]) {
            cellModel.cellHeight = [cellClass cellHeightWithModel:cellModel];
        } else {
            cellModel.cellHeight = 0.0;
        }
        
    }
    
    if (cellModel.cellWidth == CGFLOAT_MAX) { // 宽度没有缓存
        
        if ([cellClass respondsToSelector:@selector(cellWidthWithModel:)]) {
            cellModel.cellWidth = [cellClass cellWidthWithModel:cellModel];
        } else {
            cellModel.cellWidth = collectionView.bounds.size.width; // 默认跟 collection view  一样宽
        }
    }
    
    return CGSizeMake(cellModel.cellWidth, cellModel.cellHeight);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    YHCollectionViewSectionModel *sectionModel = [self collectionView:collectionView viewModelForSection:section];
    
    return sectionModel.minimumLineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    YHCollectionViewSectionModel *sectionModel = [self collectionView:collectionView viewModelForSection:section];
    
    return sectionModel.minimumInteritemSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    YHCollectionViewSectionModel *sectionModel = [self collectionView:collectionView viewModelForSection:section];
    
    return sectionModel.sectionInsets;
}

// 计算 section header 尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    YHCollectionViewSectionModel *sectionModel = [self collectionView:collectionView viewModelForSection:section];
    Class headerClass = sectionModel.headerClass;
    
    if (sectionModel.headerHeight == CGFLOAT_MAX) { // 高度没有缓存
        
        if ([headerClass respondsToSelector:@selector(heightWithModel:)]) {
            sectionModel.headerHeight = [headerClass heightWithModel:sectionModel];
        } else {
            sectionModel.headerHeight = 0.0;
        }
        
    }
    
    if (sectionModel.headerWidth == CGFLOAT_MAX) { // 宽度没有缓存
        
        if ([headerClass respondsToSelector:@selector(widthWithModel:)]) {
            sectionModel.headerWidth = [headerClass widthWithModel:sectionModel];
        } else {
            sectionModel.headerWidth = 0.0;
        }
    }
    
    
    return CGSizeMake(sectionModel.headerWidth, sectionModel.headerHeight);
}

// 计算 section footer 尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    
    YHCollectionViewSectionModel *sectionModel = [self collectionView:collectionView viewModelForSection:section];
    Class footerClass = sectionModel.footerClass;
    
    if (sectionModel.footerHeight == CGFLOAT_MAX) { // 高度没有缓存
        
        if ([footerClass respondsToSelector:@selector(heightWithModel:)]) {
            sectionModel.footerHeight = [footerClass heightWithModel:sectionModel];
        } else {
            sectionModel.footerHeight = 0.0;
        }
        
    }
    
    if (sectionModel.footerWidth == CGFLOAT_MAX) { // 宽度没有缓存
        
        if ([footerClass respondsToSelector:@selector(widthWithModel:)]) {
            sectionModel.footerWidth = [footerClass widthWithModel:sectionModel];
        } else {
            sectionModel.footerWidth = 0.0;
        }
    }
    
    return CGSizeMake(sectionModel.footerWidth, sectionModel.footerHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    YHCollectionViewCellModel *cellModel = [self collectionView:collectionView cellModelForItemAtIndexPath:indexPath];
    [cellModel collectionViewDidSelectItem:collectionView];
    
    if (cellModel.didSelectItem) {
        cellModel.didSelectItem(collectionView, indexPath);
    }
    
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [self.collectionViewDelegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)]) {
        [self.collectionViewDelegate collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)]) {
        [self.collectionViewDelegate collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0") == NO) {
        [self.sectionHeaderMap removeObjectForKey:@(indexPath.section)];
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.collectionViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.collectionViewDelegate scrollViewDidScroll:scrollView];
    }
}

#pragma mark - Private
- (void)p_setupCellCountAndSectionCountForModels {
    [self.sectionModels enumerateObjectsUsingBlock:^(YHCollectionViewSectionModel * sectionModel, NSUInteger section, BOOL * _Nonnull stop) {
        sectionModel.numberOfSectionsInCollectionView = self.sectionModels.count;
        sectionModel.section = section;
        
        [sectionModel.cellModels enumerateObjectsUsingBlock:^(YHCollectionViewCellModel * cellModel, NSUInteger item, BOOL * _Nonnull stop) {
            cellModel.numberOfItemsInSection = sectionModel.cellModels.count;
            cellModel.indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        }];
        
    }];
    
}

#pragma mark - Getter
- (NSMutableDictionary *)sectionHeaderMap {
    if (_sectionHeaderMap == nil) {
        _sectionHeaderMap = [[NSMutableDictionary alloc] init];
    }
    return _sectionHeaderMap;
}

- (NSMutableSet<Class> *)registeredCellClasses {
    if (_registeredCellClasses == nil) {
        _registeredCellClasses = [[NSMutableSet alloc] init];
    }
    return _registeredCellClasses;
}

- (NSMutableSet<NSString *> *)registeredCellNibNames {
    if (_registeredCellNibNames == nil) {
        _registeredCellNibNames = [[NSMutableSet alloc] init];
    }
    return _registeredCellNibNames;
}

- (NSMutableSet<NSString *> *)registeredSupplementaryViewIdentifiers {
    if (_registeredSupplementaryViewIdentifiers == nil) {
        _registeredSupplementaryViewIdentifiers = [[NSMutableSet alloc] init];
    }
    return _registeredSupplementaryViewIdentifiers;
}

- (NSMutableSet<NSString *> *)registeredSupplementaryViewNibNames {
    if (_registeredSupplementaryViewNibNames == nil) {
        _registeredSupplementaryViewNibNames = [[NSMutableSet alloc] init];
    }
    return _registeredSupplementaryViewNibNames;
}

- (MessageInterceptor *)delegateInterceptor {
    if (_delegateInterceptor == nil) {
        _delegateInterceptor = [[MessageInterceptor alloc] init];
        _delegateInterceptor.middleMan = self;
        _delegateInterceptor.receiver = self.collectionViewDelegate;
    }
    return _delegateInterceptor;
}

@end


