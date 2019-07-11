//
//  HYHAddImageView.h
//  HYHRotateScaleImageView
//
//  Created by huangyongheng on 2019/7/11.
//  Copyright © 2019 hyh. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 控制按钮半径 */
#define Ctrl_Radius 23/2.0

NS_ASSUME_NONNULL_BEGIN

@interface HYHAddImageView : UIView

/** 添加的图片 */
@property (nonatomic, strong) UIImage *addImage;
/** 是否处于活跃状态 */
@property (nonatomic, assign) BOOL isEditing;

/** 点击非活跃视图时的block */
@property (nonatomic, copy) void(^SetEditBlock)(void);
/** 删除视图block */
@property (nonatomic, copy) void(^RemoveViewBlock)(void);

@end

NS_ASSUME_NONNULL_END
