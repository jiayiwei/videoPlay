//
//  BarrageManager.m
//  弹幕demo
//
//  Created by z on 2016/12/28.
//  Copyright © 2016年 ja. All rights reserved.
//

#import "BarrageManager.h"
#import "BarrageView.h"
@interface BarrageManager()
@property (nonatomic, strong) NSMutableArray *allComments;
@property (nonatomic, strong) NSMutableArray *tmpComments;
@property (nonatomic, strong) NSMutableArray *visibleBarrage;//当前屏幕中显示的弹幕

@property BOOL Started;
@property BOOL StopAnimation;

@end
@implementation BarrageManager


//开始
- (void)start
{
    if (self.tmpComments.count == 0) {
        [self.tmpComments addObjectsFromArray:self.allComments];
    }
    self.Started = YES;
    self.StopAnimation = NO;
    [self initBarrageView];
}

//停止
- (void)stop
{
    self.StopAnimation = YES;
    
}
//生成一个随机轨迹，
- (void)initBarrageView
{
    NSMutableArray *arr = [NSMutableArray arrayWithObjects:@(0),@(1),@(2), nil];
    for (int i = 0; i < 3; i ++) {
        //取出一个弹幕
        NSString *comment = [self.tmpComments firstObject];
        if (comment) {
            //删除一个弹幕
            [self.tmpComments removeObjectAtIndex:0];
            //随机生成弹幕轨迹
            NSInteger index = arc4random()%arr.count;
            Trajectory trajectory = [[arr objectAtIndex:index] integerValue];
            [arr removeObjectAtIndex:index];
            [self createBulletComment:comment trajectory:trajectory];
        }else{
            break;
        }
    }
}
/**
 *  创建弹幕
 *
 *  @param comment    弹幕内容
 *  @param trajectory 弹道位置
 */
- (void)createBulletComment:(NSString *)comment trajectory:(Trajectory)trajectory
{
    //如果停止动画则停止创建弹幕
    if (self.StopAnimation) {
        return;
    }
    BarrageView *barrageView = [[BarrageView alloc] initWithContent:comment];
    barrageView.trajectory = trajectory;
    __weak BarrageView *weakBarrage = barrageView;
    __weak typeof(self) weakSelf = self;
    barrageView.moveBlock = ^(BarrageStatus status){
        switch (status) {
            case Start:{
                [self.visibleBarrage addObject:weakBarrage];
            }
                break;
            case Enter:{
                //弹幕完全进入屏幕，判断接下来时候还有内容，如果有就在改轨迹上面创建弹幕
                NSString *comment = [weakSelf nextComment];
                if (comment) {
                    [weakSelf createBulletComment:comment trajectory:trajectory];
                }else{
                //没有弹幕
                }
            }
                break;
            case End:{
                //当弹幕飞出屏幕后从queue中删除
                if ([weakSelf.visibleBarrage containsObject:weakBarrage]) {
                    [weakSelf.visibleBarrage removeObject:weakBarrage];
                }
                //说明当前屏幕已经没有弹幕
                if (weakSelf.visibleBarrage.count == 0) {
//                    [weakSelf start];//重新开始
                }
            }
                break;
                
            default:
                break;
        }
    };
    
    if (self.generateBarrageBlock) {
        self.generateBarrageBlock(barrageView);
    }
}

- (NSString *)nextComment
{
    NSString *comment = [self.tmpComments firstObject];
    if (comment) {
        [self.tmpComments removeObjectAtIndex:0];
    }
    return comment;
}
#pragma mark -懒加载
- (NSMutableArray *)allComments
{
    if (!_allComments) {
        _allComments = [NSMutableArray arrayWithObjects:
                        @"我是一条弹幕1",
                        @"我是一条弹幕我是一条弹幕2",
                        @"弹幕3",
                        @"弹幕4在这里",
                        @"弹幕5 hhh",
                        @"弹6",
                        @"hahaha",
                        @"哈哈哈哈哈",
                        @"😁😝😝😝😝😝😝",
                        @"弹幕5 hhh",
                        @"贾老师666 666 666 666 666 ",
                        @"hahaha",
                        @"贾老师好牛逼啊",
                        @"😁😝😝😝😝😝😝",
                        @"弹幕5 hhh",
                        @"弹6",
                        @"贾老师好牛逼啊",
                        @"哈哈哈哈哈",
                        @"😁😝😝😝😝😝😝",
                        @"弹幕5 hhh",
                        @"弹6",
                        @"hahaha",
                        @"哈哈哈哈哈",
                        @"😁😝😝😝😝😝😝",
                        @"弹幕5 hhh",
                        @"弹6",
                        @"hahaha",
                        @"哈哈哈哈哈",
                        @"贾老师好牛逼啊！！！",nil];
    

    }
    return _allComments;
}
- (NSMutableArray *)tmpComments
{
    if (!_tmpComments) {
        _tmpComments = [[NSMutableArray alloc] init];
    }
    return _tmpComments;
}
- (NSMutableArray *)visibleBarrage
{
    if (!_visibleBarrage) {
        _visibleBarrage = [[NSMutableArray alloc] init];
    }
    return _visibleBarrage;
}
@end
