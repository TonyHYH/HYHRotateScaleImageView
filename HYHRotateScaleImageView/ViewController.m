//
//  ViewController.m
//  HYHRotateScaleImageView
//
//  Created by huangyongheng on 2019/7/11.
//  Copyright © 2019 hyh. All rights reserved.
//

#import "ViewController.h"
#import "HYHAddImageView.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *addBtn;
@property (nonatomic, strong) UIImage *addImage;
/** 添加的图片视图数组 */
@property (nonatomic, strong) NSMutableArray *addViewList;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createSubview];
}

- (void)createSubview{
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.addBtn];
    
    [self.view addGestureRecognizer:self.tapGesture];
}

#pragma mark - event

- (void)addImageView:(UIButton *)btn{
    [self cleanSubviewEditStatus];
    CGSize viewSize = [self getAddImageViewSize];
    CGRect frame = CGRectMake((self.view.bounds.size.width-viewSize.width)/2.0, (self.view.bounds.size.height-viewSize.height)/2.0, viewSize.width, viewSize.height);
    HYHAddImageView *imageView = [[HYHAddImageView alloc]initWithFrame:frame];
    [self.view addSubview:imageView];
    [self.addViewList insertObject:imageView atIndex:0];
    imageView.addImage = self.addImage;
    imageView.isEditing = YES;
    
    
    //block
    
    __weak __typeof(&*self)weakSelf = self;
    imageView.SetEditBlock = ^{
        [weakSelf cleanSubviewEditStatus];
    };
    
    imageView.RemoveViewBlock = ^{
        for (HYHAddImageView *addView in [weakSelf.addViewList copy]) {
            if (addView.isEditing) {
                [weakSelf.addViewList removeObject:addView];
                break;
            }
        }
    };
}

#pragma mark - private

- (CGSize)getAddImageViewSize{
    CGFloat imageWidth = self.addImage.size.width;
    CGFloat imageHeight = self.addImage.size.height;
    //最终添加视图的宽高
    CGFloat width = 0;
    CGFloat height = 0;
    //默认宽高值
    CGFloat defaultWH = 100;
    if (imageWidth>imageHeight) {
        height = defaultWH;
        width = (height*imageWidth/imageHeight);
    }else{
        width = defaultWH;
        height = (width*imageHeight/imageWidth);
    }
    //视图比图片尺寸要大一个控制按钮的大小
    width += Ctrl_Radius*2;
    height += Ctrl_Radius*2;
    return CGSizeMake(width, height);
}

/** 清除所有添加子视图活动状态 */
- (void)cleanSubviewEditStatus{
    [self.addViewList enumerateObjectsUsingBlock:^(HYHAddImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isEditing) {
            obj.isEditing = NO;
        }
    }];
}

#pragma mark - 手势

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture{
    [self cleanSubviewEditStatus];
}

#pragma mark - getter

- (UIImage *)addImage{
    if (_addImage == nil) {
        _addImage = [UIImage imageNamed:@"demoImg.jpg"];
    }
    return _addImage;
}

- (UIButton *)addBtn{
    if (_addBtn == nil) {
        _addBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 20, 44, 44)];
        _addBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_addBtn setTitle:@"＋" forState:UIControlStateNormal];
        [_addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_addBtn addTarget:self action:@selector(addImageView:) forControlEvents:UIControlEventTouchUpInside];
        _addBtn.layer.cornerRadius = 22;
        _addBtn.layer.masksToBounds = YES;
        _addBtn.layer.borderColor = [UIColor blackColor].CGColor;
        _addBtn.layer.borderWidth = 1.0f;
    }
    return _addBtn;
}

- (NSMutableArray *)addViewList{
    if (_addViewList == nil) {
        _addViewList = [NSMutableArray array];
    }
    return _addViewList;
}

- (UITapGestureRecognizer *)tapGesture{
    if (_tapGesture == nil) {
        _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureAction:)];
    }
    return _tapGesture;
}

@end
