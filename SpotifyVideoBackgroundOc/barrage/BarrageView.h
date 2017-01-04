//
//  BarrageView.h
//  弹幕demo
//
//  Created by ja on 2016/12/28.
//  Copyright © 2016年 ja. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, BarrageStatus) {
    Start,
    Enter,
    End
};
typedef NS_ENUM(NSInteger,Trajectory) {
    Trajectory_1,
    Trajectory_2,
    Trajectory_3
};
@interface BarrageView : UIView
@property (nonatomic,copy) void(^moveBlock)(BarrageStatus status);
@property Trajectory trajectory;
- (instancetype)initWithContent:(NSString *)content;
- (void)startAnimation;
- (void)stopAnimation;
@end
