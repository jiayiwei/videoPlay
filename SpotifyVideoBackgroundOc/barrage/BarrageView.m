//
//  BarrageView.m
//  弹幕demo
//
//  Created by ja on 2016/12/28.
//  Copyright © 2016年 ja. All rights reserved.
//

#import "BarrageView.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define Duration   6
#define Padding  5
@interface BarrageView ()
{
    
}
@property (nonatomic,strong)UILabel *contentLable;
@end
@implementation BarrageView

- (instancetype)initWithContent:(NSString *)content{
    if (self == [super init]) {
        CGFloat width = [content sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.f]}].width;
        self.bounds = CGRectMake(0, 0, width + Padding*2, 25);
        self.contentLable = [[UILabel alloc] init];
        self.contentLable.frame = CGRectMake(Padding, 0, (width), 25);
        self.contentLable.backgroundColor = [UIColor clearColor];
        self.contentLable.text = content;
        self.contentLable.font = [UIFont systemFontOfSize:14];
        self.contentLable.textColor = [UIColor whiteColor];
        [self addSubview:self.contentLable];
    }
    return self;
}
//开始动画
- (void)startAnimation
{
    
    CGFloat overstepW = self.frame.origin.x - ScreenWidth;
    CGFloat width = CGRectGetWidth(self.frame) + ScreenWidth + overstepW;
    CGFloat speed = width /Duration;
    CGFloat dur = (CGRectGetWidth(self.frame) + overstepW)/speed;
    if (self.moveBlock) {
        self.moveBlock(Start);
    }
    /**
     * NSEC_PER_SEC 秒
     * NSEC_PER_MSEC 毫秒
     * NSEC_PER_USEC 微秒
     */
    //dur秒后执行
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dur *NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.moveBlock) {
            //dur时间后弹幕完全进入屏幕
            self.moveBlock(Enter);
        }
    });
    __block CGRect frame = self.frame;
    [UIView animateWithDuration:Duration animations:^{
        frame.origin.x = - frame.size.width;
        self.frame = frame;
        
    } completion:^(BOOL finished) {
        if (finished) {
            if (self.moveBlock) {
                self.moveBlock(End);
            }
            [self removeFromSuperview];
        }
    }];
    
    
}
- (void)stopAnimation
{
    [self.layer removeAllAnimations];
    [self removeFromSuperview];
}
@end
