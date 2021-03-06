//
//  ViewController.m
//  SpotifyVideoBackgroundOc
//
//  Created by 贾翊玮 on 16/12/1.
//  Copyright © 2016年 贾翊玮. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import "BarrageView.h"
#import "BarrageManager.h"
#import "BrightnessCustomView.h"
typedef NS_ENUM (NSInteger,GestureType){
    videoVolumeOrbrightnessGesture,
    videoMoveGesture,
    videoNoneGesture,
};
@interface ViewController ()
{
    
}

//播放器
@property (nonatomic,strong)AVPlayer *player;
@property (nonatomic,strong)AVPlayerItem *playerItem;
@property (nonatomic,strong)AVPlayerLayer *playerLayer;
@property (nonatomic,strong)UIView *playerBgView;
@property GestureType gesutreType;

//播放器顶部和底部视图
@property (nonatomic,strong)UIView *videoTopView;//视频底部控制条
@property (nonatomic,strong)UIView *videoBottomView;//视频顶部控制条
@property (nonatomic,strong)UIProgressView *progressView;//缓存进度条
@property (nonatomic,strong)UILabel *timeLabel;//播放时间
@property (nonatomic,strong)UILabel *totalTimeLable;//总得时间
@property (nonatomic,strong)UISlider *slider;//调节视频播放进度
@property (nonatomic,strong)UIButton *playOrPauseBtn;//开始、暂停
@property (nonatomic,strong)UISlider *volumeSlider;//音量调节
@property (nonatomic,strong)BrightnessCustomView *brightnessView;//亮度调节
@property (nonatomic,assign)CGFloat startSliderValue;

//控制视频的控制view隐藏与显示
@property (nonatomic,strong)NSTimer *timer;

//变量
@property (nonatomic,assign)long long totalSeconds;//视频总得时间
@property (nonatomic,strong)id timeServer;//定时器服务
@property (nonatomic,assign)CGPoint startPonint;//手势的起始点
@property (nonatomic,assign)CGFloat startVB;//记录手指触摸时的音量和亮度的初始值（v:volume b:Brightness）
@property (nonatomic,assign)BOOL isMove;//是否在移动
@property (nonatomic,assign)BOOL isPlaying;//是否正在播放
@end
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define videoBootomViewH 50.f
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isMove = NO;
    /*创建播放器*/
    [self loadAVPlayer];
    [self createVideoBottomView];
    [self createVideoTopView];
    [self createDanmuView];
    [self configVulumSlider];
    self.brightnessView.center = self.playerBgView.center;
    [self.playerBgView addSubview:self.brightnessView];
    self.gesutreType = videoNoneGesture;
 
}
//隐藏信号栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-  (void)loadAVPlayer
{

    NSURL *videoURL = [NSURL URLWithString:@"http://f01.v1.cn/group2/M00/01/62/ChQB0FWBQ3SAU8dNJsBOwWrZwRc350-m.mp4"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    //获取播放的总时长
    long long dur = CMTimeGetSeconds(asset.duration);
    self.totalSeconds = dur;
    
    //获取playerItem
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.playerItem addObserver:self forKeyPath:@"presentationSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    //获取player
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    //获取playerlayer
    AVPlayerLayer *playerlayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerlayer.backgroundColor = [UIColor blackColor].CGColor;
    self.playerLayer = playerlayer;
    playerlayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerlayer.frame =  CGRectMake(0, 0, self.playerBgView.frame.size.width, self.playerBgView.frame.size.height);
    
    //add
    [self.playerBgView.layer addSublayer:playerlayer];
    [self.view addSubview:self.playerBgView];
    
    //开始播放
    [self play];
    self.timer=[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(videoControlViewHide) userInfo:nil repeats:YES];

    
    
}
//创建视图顶部控制条
- (void)createVideoTopView
{
    
    self.videoTopView.frame = CGRectMake(0, 0, 50, 50);
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(15, 10, 30, 30);
    [back setImage:[UIImage imageNamed:@"playermini_back"] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.playerBgView addSubview:self.videoTopView];
}
//创建视图底部控制条
- (void)createVideoBottomView
{
    CGRect playerLayerRect = self.playerLayer.frame;
    
   
    self.videoBottomView.frame = CGRectMake(0, playerLayerRect.size.height - videoBootomViewH, playerLayerRect.size.width, videoBootomViewH);
    
    /*暂停播放*/
    UIButton *pauseOrPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [pauseOrPlay setBackgroundImage:[UIImage imageNamed:@"ad_pause_f_p"] forState:UIControlStateNormal];
    [pauseOrPlay setBackgroundImage:[UIImage imageNamed:@"ad_play_f_p"] forState:UIControlStateSelected];
    [pauseOrPlay addTarget:self action:@selector(pauseOrPlayAction:) forControlEvents:UIControlEventTouchUpInside];
    pauseOrPlay.showsTouchWhenHighlighted = YES;
    pauseOrPlay.frame = CGRectMake(0,0 , videoBootomViewH, videoBootomViewH);
    self.playOrPauseBtn = pauseOrPlay;
    
    /*缩放按钮*/
    UIButton *playFull = [UIButton buttonWithType:UIButtonTypeCustom];
    [playFull setBackgroundImage:[UIImage imageNamed:@"play_full_f_p"] forState:UIControlStateNormal];
    [playFull setBackgroundImage:[UIImage imageNamed:@"play_mini_f_p"] forState:UIControlStateSelected];
    [playFull addTarget:self action:@selector(playFullAction:) forControlEvents:UIControlEventTouchUpInside];
    playFull.showsTouchWhenHighlighted = YES;
    playFull.frame = CGRectMake(playerLayerRect.size.width - videoBootomViewH, 0, videoBootomViewH, videoBootomViewH);
    playFull.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    /*创建缓存进度条*/
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView = progressView;
    progressView.progress = 0.5;
    progressView.frame = CGRectMake(0, 0, playerLayerRect.size.width, 1);
    progressView.progressTintColor = [UIColor grayColor];
    progressView.backgroundColor = [UIColor whiteColor];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    /*创建播放时间*/
    UILabel *timeLable = [[UILabel alloc] init];
    timeLable.frame = CGRectMake(CGRectGetMaxX(pauseOrPlay.frame), 0, 100, videoBootomViewH);
    timeLable.font = [UIFont systemFontOfSize:14.f];
    timeLable.text = @"00:00:00";
    timeLable.textColor = [UIColor whiteColor];
    timeLable.backgroundColor = [UIColor clearColor];
    timeLable.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    timeLable.textAlignment = 0;
    self.timeLabel = timeLable;
    
    /*创建总得时间*/
    UILabel *totalLable = [[UILabel alloc] init];
    totalLable.frame = CGRectMake( playFull.frame.origin.x - 100, 0, 100, videoBootomViewH);
    totalLable.textColor = [UIColor whiteColor];
    totalLable.text =@"00:00:00";
    totalLable.textAlignment = 2;
    totalLable.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    totalLable.font = [UIFont systemFontOfSize:14.f];
    self.totalTimeLable = totalLable;
    
    /*创建拖动进度条*/
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, -19.5, playerLayerRect.size.width, 40)];
    slider.minimumTrackTintColor = [UIColor greenColor];
    slider.maximumTrackTintColor = [UIColor clearColor];
    [slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(sliderVlaueChange:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(sliderTouchEnd:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(sliderTouchEnd:) forControlEvents:UIControlEventTouchUpOutside];
    [slider addTarget:self action:@selector(sliderTouchEnd:) forControlEvents:UIControlEventTouchCancel];

    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [slider setThumbImage:[UIImage imageNamed:@"MoviePlayer_Slider"] forState:UIControlStateNormal];
    self.slider = slider;
    
    [self.playerBgView addSubview:self.videoBottomView];
    [self.videoBottomView addSubview:pauseOrPlay];
    [self.videoBottomView addSubview:playFull];
    [self.videoBottomView addSubview:progressView];
    [self.videoBottomView addSubview:timeLable];
    [self.videoBottomView addSubview:totalLable];
    [self.videoBottomView addSubview:slider];
    
    
    

}
//创建弹幕
- (void)createDanmuView
{
    BarrageManager *manager = [[BarrageManager alloc] init];
    __weak typeof(self) weakSelf = self;
    manager.generateBarrageBlock = ^(BarrageView *view){
        view.frame = CGRectMake(weakSelf.playerBgView.frame.size.width + 50, 20 + 34 * view.trajectory, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds));
        [weakSelf.view addSubview:view];
        [view startAnimation];
    };
    [manager start];
}
//获取系统音量slider
- (void)configVulumSlider
{
    MPVolumeView *volume = [[MPVolumeView alloc] init];
    [volume sizeToFit];
    for (UIView *view in [volume subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeSlider = (UISlider *)view;
            break;
        }
    }
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error];
    
    
    if (!success) {/* error */}
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}
#pragma mark -
#pragma mark - action
- (void)backAction
{
    
}
//播放与暂停
- (void)pauseOrPlayAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self pause];
    }else {
        [self play];
    }
}
//视频旋转
- (void)playFullAction:(UIButton *)sender
{
    [self fullOrMiniloadSubviewsFrame:sender];
}
//slider值改变
- (void)sliderVlaueChange:(UISlider *)sender
{
    
     NSLog(@"改变");
    CMTime changeValue = CMTimeMakeWithSeconds(sender.value, 1);
//    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changeValue completionHandler:^(BOOL finished) {
      
    }];
    
    
}
//slider触碰结束
- (void)sliderTouchEnd:(UISlider *)sender
{
    NSLog(@"结束");
    self.playOrPauseBtn.selected = NO;
    [self play];
    [self videoControlViewOutHide];
}
//slider开始点击
- (void)sliderTouchDown:(UISlider *)sender
{
    NSLog(@"开始");
    [self.timer invalidate];//开始点击slider 销毁定时器（取消隐藏播放器的控制view）
    self.playOrPauseBtn.selected = YES;
    [self pause];
}
//- (void)
#pragma mark -
#pragma mark - kvo 监听播放状态
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {    //获取到视频信息的状态, 成功就可以进行播放, 失败代表加载失败
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {//准备好播放
            [self readyPlay];
        }else if(self.playerItem.status == AVPlayerItemStatusFailed){//加载失败
            NSLog(@"视频播放失败");
        }else if(self.playerItem.status == AVPlayerItemStatusUnknown){//未知错误
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){//当缓冲进度有变化的时候
        NSLog(@"loadedTimeRanges");
        [self setProgressVlaue];
        
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){//当视频播放因为各种状态播放停止的时候, 这个属性会发生变化
        NSLog(@"playbackLikelyToKeepUp");
        
    }else if([keyPath isEqualToString:@"playbackBufferEmpty"]){//当没有任何缓冲部分可以播放的时候
        
        NSLog(@"playbackBufferEmpty");
    }else if ([keyPath isEqualToString:@"playbackBufferFull"]){
        NSLog(@"playbackBufferFull: change : %@", change);
    }else if([keyPath isEqualToString:@"presentationSize"]){ //获取到视频的大小的时候调用
        
    }
}
#pragma mark -
#pragma mark - 手势触摸 （控制音量、亮度、和快进的逻辑）
//开始触摸
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    //如果点击的不是播放器，不做相应
    if (![[touches.anyObject view] isEqual:self.playerBgView]) {
        return;
    }
    //如果是多个手指不做处理
    if (touches.count > 1 || [touch tapCount] > 1 || event.allTouches.count > 1) {
        return;
    }
    CGPoint currentPoint = [touch locationInView:self.playerBgView];
    
    //记录首次触摸的坐标
    self.startPonint = currentPoint;
    if (self.startPonint.x <= self.playerBgView.frame.size.width/2.f) {//左边音量
        self.startVB = self.volumeSlider.value;
    }else{//右边亮度
        self.startVB = [UIScreen mainScreen].brightness;
    }
    self.startSliderValue = self.slider.value;//手势开始时播放进度
    self.isMove = NO;//记录用户是否是滑动
   
    
}
//触摸结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = (UITouch *)touches.anyObject;

    //如果点击的不是播放器，不做相应
    if (![[touches.anyObject view] isEqual:self.playerBgView]) {
        return;
    }
    //如果是多个手指不做处理
    if (touches.count > 1 || [touch tapCount] > 1 || event.allTouches.count > 1) {
        return;
    }
    
    //控制播放器顶部和底部控制条的隐藏与显示
    if (self.isMove == NO) {
        if (self.videoTopView.hidden) {
            [self videoControlViewOutHide];
        }else{
            [self videoControlViewHide];
        }
        
    }else{
        [self videoControlViewOutHide];
    }
    
    [self play];
    
    
    self.gesutreType = videoNoneGesture;

}
//拖动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.timer.isValid) {
        [self.timer invalidate];
    }
    if (self.isPlaying) {
        [self pause];
    }
    
    
    UITouch *touch = [touches anyObject];
    //如果点击的不是播放器，不做相应
    if (![[touches.anyObject view] isEqual:self.playerBgView]) {
        return;
    }
    //如果是多个手指不做处理
    if (touches.count > 1 || [touch tapCount] > 1 || event.allTouches.count > 1) {
        return;
    }
    self.isMove = YES;
    CGPoint location = [touch locationInView:self.playerBgView];
    CGPoint distancePoint = CGPointMake(location.x - self.startPonint.x, location.y - self.startPonint.y);
    //判断用户滑动的方向
    if (self.gesutreType == videoNoneGesture) {
        if (fabs(distancePoint.x) >= 30) {//30是最小移动距离（自己随便定义）
            //进度
            self.gesutreType = videoMoveGesture;
        }else if (fabs(distancePoint.y) >= 30){
            //音量和亮度
            self.gesutreType = videoVolumeOrbrightnessGesture;
        }
    }
    switch (self.gesutreType) {
        case videoMoveGesture://调节播放进度
        {
            CGFloat rate = self.startSliderValue+ distancePoint.x / 30;
            rate = rate > self.totalSeconds ? self.totalSeconds : rate;
            rate = rate < 0 ? 0 : rate;
            NSLog(@"rate=%f",rate);
            [self.slider setValue:rate animated:YES];
            [self sliderVlaueChange:self.slider];
        }
            
            
            break;
        case videoVolumeOrbrightnessGesture://调节音量或者亮度
            if (self.startPonint.x <= self.playerBgView.frame.size.width / 2.0) {//左边调节音量
                
                if (distancePoint.y < 0) {
                    //增大音量
                    [self.volumeSlider setValue:self.startVB + (-distancePoint.y / 30.0 / 10) animated:YES];
                    if (self.startVB + (-distancePoint.y / 30 / 10) - self.volumeSlider.value >= 0.1) {
                        [self.volumeSlider setValue:0.1 animated:NO];
                        [self.volumeSlider setValue:self.startVB + (-distancePoint.y / 30.0 / 10) animated:YES];
                    }
                    
                } else {
                    //减少音量
                    [self.volumeSlider setValue:self.startVB - (distancePoint.y / 30.0 / 10) animated:YES];
                }
                
            }else{//右边调节亮度
                if (distancePoint.y < 0) {
                    //增加亮度
                    [[UIScreen mainScreen] setBrightness:self.startVB + (-distancePoint.y / 30.0 / 10)];
                } else {
                    //减少亮度
                    [[UIScreen mainScreen] setBrightness:self.startVB - (distancePoint.y / 30.0 / 10)];
                }
            }
            break;
            
        default:
            break;
    }
}
//准备播放
- (void)readyPlay
{
    //设置播放时间
    [self setPlayTimeAndTotalTime];
    self.slider.minimumValue = .0;
    self.slider.maximumValue = self.totalSeconds;
   
}
//暂停
- (void)pause{
    self.isPlaying = YES;
    [self.player pause];
    
}
//播放
- (void)play{
    self.isPlaying = NO;
    [self.player play];
}
//设置缓存进度 progress
- (void)setProgressVlaue
{
    NSArray *loadedTimeRandes = self.playerItem.loadedTimeRanges;
    CMTimeRange timeRange = [loadedTimeRandes.firstObject CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;
    self.progressView.progress = result/self.totalSeconds;
}
//设置播放时间 和剩余时间
- (void)setPlayTimeAndTotalTime
{
    self.totalTimeLable.text = [self calculateTimeWithTimeFormatter:self.totalSeconds];
    //这个方法相当于倒计时，使用完后要注意移除。关于CMTimeMake的介绍:
    //https://zwo28.wordpress.com/2015/03/06/%E8%A7%86%E9%A2%91%E5%90%88%E6%88%90%E4%B8%ADcmtime%E7%9A%84%E7%90%86%E8%A7%A3%EF%BC%8C%E4%BB%A5%E5%8F%8A%E5%88%A9%E7%94%A8cmtime%E5%AE%9E%E7%8E%B0%E8%BF%87%E6%B8%A1%E6%95%88%E6%9E%9C/
    __weak typeof(self) weakSelf = self;
    self.timeServer =  [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
        long long seconds =weakSelf.playerItem.currentTime.value / weakSelf.playerItem.currentTime.timescale;
        weakSelf.timeLabel.text = [weakSelf calculateTimeWithTimeFormatter:seconds];
        [weakSelf.slider setValue:seconds animated:YES];
    }];
}
//旋转时候更新视图frame
- (void)fullOrMiniloadSubviewsFrame:(UIButton *)sender
{
    
    sender.selected = !sender.selected;
    
    //向右边旋转全屏
    Float64 rotation =M_PI_2;//设置旋转角度，向右旋转90°
    CGFloat height  = ScreenWidth;//向右边旋转后手机的宽度变成视频视图的高度
    CGFloat width = ScreenHeight;//向右边旋转后手机的高度变成视频视图的宽度
    CGFloat playerW = ScreenHeight;//同理
    CGFloat playerH = ScreenWidth;//同理
    
    //向左边旋转小屏
    if (!sender.selected) {
        rotation = 0;//向左旋转90°
        height = ScreenHeight;
        width = ScreenWidth;
        playerW = ScreenWidth;
        playerH = 200;
    }
    [UIView beginAnimations:nil context:nil];
    self.view.transform = CGAffineTransformMakeRotation(rotation);
    self.view.bounds = CGRectMake(0, 0, width, height);
    self.playerBgView.frame = CGRectMake(0, 0, playerW, playerH);
    self.playerLayer.frame = CGRectMake(0, 0, playerW, playerH);
    self.videoBottomView.frame = CGRectMake(0, self.playerBgView.frame.size.height - videoBootomViewH, self.playerBgView.frame.size.width, videoBootomViewH);
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];
}
//视频控制view隐藏
- (void)videoControlViewHide
{
    self.videoBottomView.hidden = YES;
    self.videoTopView.hidden = YES;
    [self.timer invalidate];
}
//视频控制view退出隐藏，重新开始
- (void)videoControlViewOutHide
{
    self.videoBottomView.hidden = NO;
    self.videoTopView.hidden = NO;
    if (self.timer.valid) {
        
         self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(videoControlViewHide) userInfo:nil repeats:NO];
    }else{
        
        //在开始一个新的计时时，先把之前的计时给杀掉，防止先前的计时提前隐藏视频控制view
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(videoControlViewHide) userInfo:nil repeats:NO];
    }
    
}
#pragma mark -
#pragma mark - getter/setter
- (UIView *)videoTopView
{
    if (!_videoTopView) {
        _videoTopView = [[UIView alloc] init];
        _videoTopView.backgroundColor = [UIColor blackColor];
        _videoTopView.alpha = 0.5;
        _videoTopView.autoresizesSubviews = YES;
        _videoTopView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    }
    return _videoTopView;
}
- (UIView *)videoBottomView
{
    if (!_videoBottomView) {
        _videoBottomView = [[UIView alloc] init];
        _videoBottomView.backgroundColor = [UIColor blackColor];
        _videoBottomView.alpha = 0.5;
        //设置这个东西有局限性，所以还是写了fullOrMiniloadSubviewsFrame这个方法😭
        _videoBottomView.autoresizingMask =UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;

        /*允许子视图跟着父视图变化，子视图需要设置autoresizingMask配合使用*/
        self.videoBottomView.autoresizesSubviews = YES;
        
    }
    return _videoBottomView;
}
- (UIView *)playerBgView
{
    if (!_playerBgView) {
        _playerBgView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 200)];
        _playerBgView.autoresizesSubviews = YES;
        _playerBgView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    }
    return _playerBgView;
}
- (BrightnessCustomView *)brightnessView
{
    if (!_brightnessView) {
        _brightnessView = [[BrightnessCustomView alloc] initWithFrame:CGRectMake(0, 0, kVideoBrightnessIndicatorViewSide, kVideoBrightnessIndicatorViewSide)];
        
    }
    return _brightnessView;
}
/// 耳机插入、拔出事件
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSInteger routeChangeReason = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"---耳机插入");
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            NSLog(@"---耳机拔出");
            
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
            
        default:
            break;
    }
}



#pragma mark -
#pragma mark - other

//获取视频的缩略图
- (UIImage *)getImageVideo:(NSString *)videoUrl
{
    UIImage *image = nil;
    @try {
        
        
        //根据URL获取AVURLAsset
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:videoUrl] options:nil];
        
        //更具AVURLAsset 获取AVAssetImageGenerator
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:urlAsset];
        
        // 截图的时候调整到正确的方向
        gen.appliesPreferredTrackTransform = YES;
        
        
        CMTime time = CMTimeMakeWithSeconds(1.0, 30);//截取1.0秒处的图片，30 为每秒30帧
        
        CGImageRef cgImage = [gen copyCGImageAtTime:time actualTime:nil error:nil];
        
        image = [UIImage imageWithCGImage:cgImage];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
    return image;
}
- (NSString *)calculateTimeWithTimeFormatter:(long long)timeSecond{
    NSString * theLastTime = nil;
    if (timeSecond < 60) {
        theLastTime = [NSString stringWithFormat:@"00:%.2lld", timeSecond];
    }else if(timeSecond >= 60 && timeSecond < 3600){
        theLastTime = [NSString stringWithFormat:@"%.2lld:%.2lld", timeSecond/60, timeSecond%60];
    }else if(timeSecond >= 3600){
        theLastTime = [NSString stringWithFormat:@"%.2lld:%.2lld:%.2lld", timeSecond/3600, timeSecond%3600/60, timeSecond%60];
    }
    return theLastTime;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc
{
    //移除播放倒计时服务
    [self.player removeTimeObserver:self.timeServer];
    [self removeObserver:self forKeyPath:AVAudioSessionRouteChangeNotification];
}

/*如果你想一进入该控制器的时候就强制旋转，可以设置下面的属性，跟上面的可以根据需求来定义*/
//#pragma mark- 设置横盘与状态栏
//- (BOOL)prefersStatusBarHidden{
//    return YES;
//}
////允许横屏旋转
//- (BOOL)shouldAutorotate
//{
//    return self.isAutororate;
//}
////支持左右旋转
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft;
//}
////默认右旋转
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
//{
//    return UIInterfaceOrientationLandscapeRight;
//}
@end
