//
//  HYHAddImageView.m
//  HYHRotateScaleImageView
//
//  Created by huangyongheng on 2019/7/11.
//  Copyright © 2019 hyh. All rights reserved.
//

#import "HYHAddImageView.h"

@interface HYHAddImageView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
/** 旋转缩放控制按钮 */
@property (nonatomic, strong) UIImageView *rotateCtrl;
/** 删除视图控制按钮 */
@property (nonatomic, strong) UIImageView *removeCtrl;

/** 旋转缩放参考点 */
@property (nonatomic, assign) CGPoint originalPoint;
/** 视图初始化宽高 */
@property (nonatomic, assign) CGFloat originalWidth;
@property (nonatomic, assign) CGFloat originalHeight;
/** 记录上一个控制点 */
@property (nonatomic, assign) CGPoint lastCtrlPoint;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;//点击手势
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;//平移手势
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;//捏合手势
@property (nonatomic, strong) UIRotationGestureRecognizer *rotateGesture;//旋转手势

@end

@implementation HYHAddImageView

- (instancetype)init{
    if (self = [super init]) {
        [self createSubview];
        [self setupData];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self createSubview];
        [self setupData];
    }
    return self;
}

- (void)createSubview{
    [self addSubview:self.imageView];
    [self addSubview:self.rotateCtrl];
    [self addSubview:self.removeCtrl];
    
    [self addViewGesture];
}

- (void)setupData{
    //参考点默认为视图中心，point值为中心点比例
    self.originalPoint = CGPointMake(0.5, 0.5);
    self.originalWidth = self.frame.size.width;
    self.originalHeight = self.frame.size.height;
}

- (void)addViewGesture{
    self.panGesture.delegate = self;
    [self addGestureRecognizer:self.tapGesture];
}

#pragma mark - === 手势操作 ===

- (void)rotateAction:(UIRotationGestureRecognizer *)rotateGesture{
    NSUInteger touchCount = rotateGesture.numberOfTouches;
    if (touchCount <= 1) {
        return;
    }
    
    CGPoint p1 = [rotateGesture locationOfTouch: 0 inView:self];
    CGPoint p2 = [rotateGesture locationOfTouch: 1 inView:self];
    CGPoint newCenter = CGPointMake((p1.x+p2.x)/2,(p1.y+p2.y)/2);
    self.originalPoint = CGPointMake(newCenter.x/self.bounds.size.width, newCenter.y/self.bounds.size.height);
    
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = oPoint;
    
    self.transform = CGAffineTransformRotate(self.transform, rotateGesture.rotation);
    rotateGesture.rotation = 0;
    
    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));
}

- (void)pinchAction:(UIPinchGestureRecognizer *)pinchGesture{
    NSUInteger touchCount = pinchGesture.numberOfTouches;
    if (touchCount <= 1) {
        return;
    }
    
    CGPoint p1 = [pinchGesture locationOfTouch: 0 inView:self];
    CGPoint p2 = [pinchGesture locationOfTouch: 1 inView:self];
    CGPoint newCenter = CGPointMake((p1.x+p2.x)/2,(p1.y+p2.y)/2);
    self.originalPoint = CGPointMake(newCenter.x/self.bounds.size.width, newCenter.y/self.bounds.size.height);
    
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = oPoint;
    
    CGFloat scale = pinchGesture.scale;
    
    if (scale < 1 && self.frame.size.width <= self.originalWidth/2) {
        //当缩小到初始化宽高的一半时，停止缩小
    }else{
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        [self fitCtrlScaleX:scale scaleY:scale];
    }
    
    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));
    pinchGesture.scale = 1;
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture{
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGesture translationInView:self.superview];
        [self setCenter:(CGPoint){self.center.x + translation.x, self.center.y + translation.y}];
        [panGesture setTranslation:CGPointZero inView:self.superview];
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture{
    if (self.isEditing == NO) {
        
        if (self.SetEditBlock) {
            self.SetEditBlock();
        }
        
        self.isEditing = YES;
    }
}

#pragma mark - === 视图控制按钮 手势事件 ===

//缩放旋转
- (void)rotateCtrlPanGesture:(UIPanGestureRecognizer *)panGesture{
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        self.lastCtrlPoint = [self convertPoint:self.rotateCtrl.center toView:self.superview];
        return;
    }
    
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    CGPoint ctrlPoint = [panGesture locationInView:self.superview];
    [self scaleViewWithCtrlPoint:ctrlPoint];
    [self rotateViewWithCtrlPoint:ctrlPoint];
    self.lastCtrlPoint = ctrlPoint;
}

//移除视图
- (void)removeCtrlTapGesture:(UITapGestureRecognizer *)tapGesture{
    if (self.RemoveViewBlock) {
        self.RemoveViewBlock();
    }
    [self removeFromSuperview];
}

#pragma mark - === 旋转 ===

- (void)rotateViewWithCtrlPoint:(CGPoint)ctrlPoint {
    
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x - (self.center.x - oPoint.x),
                              self.center.y - (self.center.y - oPoint.y));
    
    
    float angle = atan2(self.center.y - ctrlPoint.y, ctrlPoint.x - self.center.x);
    float lastAngle = atan2(self.center.y - self.lastCtrlPoint.y, self.lastCtrlPoint.x - self.center.x);
    angle = - angle + lastAngle;
    self.transform = CGAffineTransformRotate(self.transform, angle);
    
    
    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));
}

#pragma mark - === 缩放 ===

/* 等比缩放 */
- (void)scaleViewWithCtrlPoint:(CGPoint)ctrlPoint {
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = oPoint;
    
    //上一个控制点距离中心的距离
    CGFloat preDistance = [self distanceWithStartPoint:self.center endPoint:self.lastCtrlPoint];
    //当前控制点距离中心的距离
    CGFloat newDistance = [self distanceWithStartPoint:self.center endPoint:ctrlPoint];
    CGFloat scale = newDistance / preDistance;
    
    if (scale < 1 && self.frame.size.width <= self.originalWidth/2) {
        //当缩小到初始化宽高一半时，停止缩小
    }else{
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        [self fitCtrlScaleX:scale scaleY:scale];
    }
    
    
    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));
}

#pragma mark - private

/* 控制按钮保持大小不变 */
- (void)fitCtrlScaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY {
    self.removeCtrl.transform = CGAffineTransformScale(self.removeCtrl.transform, 1/scaleX, 1/scaleY);
    self.rotateCtrl.transform = CGAffineTransformScale(self.rotateCtrl.transform, 1/scaleX, 1/scaleY);
}

/* 计算两点间距 */
- (CGFloat)distanceWithStartPoint:(CGPoint)start endPoint:(CGPoint)end {
    CGFloat x = start.x - end.x;
    CGFloat y = start.y - end.y;
    return sqrt(x * x + y * y);
}

/** 获取参考点坐标 */
- (CGPoint)getRealOriginalPoint {
    return CGPointMake(self.bounds.size.width * self.originalPoint.x,
                       self.bounds.size.height * self.originalPoint.y);
}

#pragma mark - UIGestureRecognizerDelegate

/* 同时触发多个手势 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

/* 当点击旋转控制按钮时，禁止全图平移手势 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer.view == self) {
        CGPoint p = [touch locationInView:self];
        if (CGRectContainsPoint(self.rotateCtrl.frame, p)) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - setter

- (void)setAddImage:(UIImage *)addImage{
    _addImage = addImage;
    self.imageView.image = addImage;
}

- (void)setIsEditing:(BOOL)isEditing{
    _isEditing = isEditing;
    if (isEditing) {
        self.removeCtrl.hidden = NO;
        self.rotateCtrl.hidden = NO;
        if (![self.gestureRecognizers containsObject:self.panGesture]) {
            [self addGestureRecognizer:self.panGesture];
        }
        if (![self.gestureRecognizers containsObject:self.pinchGesture]) {
            [self addGestureRecognizer:self.pinchGesture];
        }
        if (![self.gestureRecognizers containsObject:self.rotateGesture]) {
            [self addGestureRecognizer:self.rotateGesture];
        }
    }else{
        self.removeCtrl.hidden = YES;
        self.rotateCtrl.hidden = YES;
        if ([self.gestureRecognizers containsObject:self.panGesture]) {
            [self removeGestureRecognizer:self.panGesture];
        }
        if ([self.gestureRecognizers containsObject:self.pinchGesture]) {
            [self removeGestureRecognizer:self.pinchGesture];
        }
        if ([self.gestureRecognizers containsObject:self.rotateGesture]) {
            [self removeGestureRecognizer:self.rotateGesture];
        }
    }
}

#pragma mark - getter

- (UIImageView *)imageView{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(Ctrl_Radius, Ctrl_Radius, self.frame.size.width-Ctrl_Radius*2, self.frame.size.height-Ctrl_Radius*2)];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}

- (UIImageView *)removeCtrl{
    if (_removeCtrl == nil) {
        _removeCtrl = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, Ctrl_Radius*2, Ctrl_Radius*2)];
        _removeCtrl.userInteractionEnabled = YES;
        _removeCtrl.image = [UIImage imageNamed:@"AddView_close"];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(removeCtrlTapGesture:)];
        [_removeCtrl addGestureRecognizer:tapGesture];
    }
    return _removeCtrl;
}

- (UIImageView *)rotateCtrl{
    if (_rotateCtrl == nil) {
        _rotateCtrl = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width-Ctrl_Radius*2, self.frame.size.height-Ctrl_Radius*2, Ctrl_Radius*2, Ctrl_Radius*2)];
        _rotateCtrl.image = [UIImage imageNamed:@"AddView_rotate"];
        _rotateCtrl.userInteractionEnabled = YES;
        _rotateCtrl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateCtrlPanGesture:)];
        [_rotateCtrl addGestureRecognizer:panGesture];
    }
    return _rotateCtrl;
}

- (UIRotationGestureRecognizer *)rotateGesture{
    if (_rotateGesture == nil) {
        _rotateGesture = [[UIRotationGestureRecognizer alloc]initWithTarget:self action:@selector(rotateAction:)];
        _rotateGesture.delegate = self;
    }
    return _rotateGesture;
}

- (UIPinchGestureRecognizer *)pinchGesture{
    if (_pinchGesture == nil) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchAction:)];
        _pinchGesture.delegate = self;
    }
    return _pinchGesture;
}

- (UIPanGestureRecognizer *)panGesture{
    if (_panGesture == nil) {
        _panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureAction:)];
    }
    return _panGesture;
}

- (UITapGestureRecognizer *)tapGesture{
    if (_tapGesture == nil) {
        _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureAction:)];
    }
    return _tapGesture;
}

@end
