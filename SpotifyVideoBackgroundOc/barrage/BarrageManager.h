//
//  BarrageManager.h
//  弹幕demo
//
//  Created by ja on 2016/12/28.
//  Copyright © 2016年 ja. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BarrageManager : NSObject
@property (nonatomic,copy)void(^generateBarrageBlock)(id view);
- (void)start;
- (void)stop;

@end
