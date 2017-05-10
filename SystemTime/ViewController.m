//
//  ViewController.m
//  SystemTime
//
//  Created by mintou on 2017/5/8.
//  Copyright © 2017年 mintou. All rights reserved.
//

#import "ViewController.h"
#include <sys/sysctl.h>
#import <Masonry.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

@property (nonatomic,assign) NSTimeInterval serverTimeTop; // 模拟服务器时间
@property (nonatomic,assign) NSTimeInterval serverTimeBottom;

@property (nonatomic,assign) NSTimeInterval appStartTimeTop; //---> 用错误的NSProcess
@property (nonatomic,assign) NSTimeInterval appStartTimeBottom;// ---> 用准确的kernel内核时间

@property (nonatomic,strong) dispatch_source_t timer;
@property (nonatomic,strong) NSDateFormatter *formatter;


// 代码实现内容包裹和均分
@property (nonatomic,strong) UIView *backView;

// 均分父视图（父视图X,Y,W,H都已知，代表frame已定）
@property (nonatomic,strong) UIView *averageView;
@property (nonatomic,strong) UIView *averageLeftView;
@property (nonatomic,strong) UIView *averageRightView;

// 用子视图的内容来填充赋值父视图的frame 父视图已知X,Y，height和width都是由子视图来填充
@property (nonatomic,strong) UIView *fillBackView;
@property (nonatomic,strong) UIView *fillLeftView;
@property (nonatomic,strong) UIView *fillMiddleView;
@property (nonatomic,strong) UIView *fillRightView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.formatter = [[NSDateFormatter alloc] init];
    [self.formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [self refreshTime:nil];
    [self refreshDataForCountDown];
    
    self.backView  = [[UIView alloc] init];
    self.backView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
    [self.view addSubview:self.backView];
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@([UIScreen mainScreen].bounds.size.height/2.5));
    }];
    
    
    self.averageView = [[UIView alloc] init];
    self.averageView.backgroundColor = [UIColor blackColor];
    [self.backView addSubview:self.averageView];
    [self.averageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.backView);
        make.height.equalTo(self.backView.mas_height).multipliedBy(0.5);
    }];

    
    self.averageLeftView = [[UIView alloc] init];
    self.averageLeftView.backgroundColor = [UIColor blueColor];
    [self.averageView addSubview:self.averageLeftView];
    [self.averageLeftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.averageView).with.offset(10);
        make.bottom.equalTo(self.averageView).with.offset(-10);
    }];
    
    self.averageRightView = [[UIView alloc] init];
    self.averageRightView.backgroundColor = [UIColor greenColor];
    [self.averageView addSubview:self.averageRightView];
    [self.averageRightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(self.averageView).with.offset(-10);
        make.top.equalTo(self.averageView).with.offset(10);
        make.left.equalTo(self.averageLeftView.mas_right).with.offset(10);
        make.width.equalTo(self.averageLeftView.mas_width);
    }];
    
    
    self.fillBackView = [[UIView alloc] init];
    self.fillBackView.backgroundColor = [UIColor purpleColor];
    [self.backView addSubview:self.fillBackView];
    // 包裹内容
    [self.fillBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.averageView.mas_bottom).with.offset(30);
        make.centerX.equalTo(self.backView);
    }];
    
    // 子视图填充
    self.fillLeftView = [[UIView alloc]  init];
    self.fillLeftView.backgroundColor = [UIColor redColor];
    [self.fillBackView addSubview:self.fillLeftView];
    
    [self.fillLeftView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.fillBackView).with.offset(10);
        make.centerY.equalTo(self.fillBackView);
        make.left.equalTo(self.fillBackView).with.offset(10);
//        make.bottom.equalTo(self.fillBackView).with.offset(-10);
        make.size.mas_equalTo(CGSizeMake(80, 60));
        
    }];
    
    self.fillMiddleView = [[UIView alloc]  init];
    self.fillMiddleView.backgroundColor = [UIColor orangeColor];
    [self.fillBackView addSubview:self.fillMiddleView];
    
    [self.fillMiddleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.fillLeftView.mas_right).with.offset(10);
        make.centerY.equalTo(self.fillBackView);
//        make.top.equalTo(self.fillBackView).with.offset(10);
//        make.bottom.equalTo(self.fillBackView).with.offset(-10);
        make.size.mas_equalTo(CGSizeMake(30, 60));
        
    }];
    
    
    self.fillRightView = [[UIView alloc]  init];
    self.fillRightView.backgroundColor = [UIColor blueColor];
    [self.fillBackView addSubview:self.fillRightView];
    [self.fillRightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(self.fillBackView).with.offset(-10);
        make.top.equalTo(self.fillBackView).with.offset(10);
        make.left.equalTo(self.fillMiddleView.mas_right).with.offset(10);
        make.size.mas_equalTo(CGSizeMake(200, 100));
    }];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.fillRightView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@10);
    }];
    
    [self.averageRightView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.averageLeftView.mas_right).with.offset(300);
    }];
    
    
    [UIView animateWithDuration:2.0f animations:^{
        [self.fillBackView layoutIfNeeded];
        [self.averageView layoutIfNeeded];
        self.backView.hidden = YES;
    }];
}
- (IBAction)refreshTime:(id)sender {
    self.serverTimeTop = [[NSDate date] timeIntervalSince1970];
    self.serverTimeBottom = [[NSDate date] timeIntervalSince1970];
    
    self.appStartTimeTop = [[NSProcessInfo processInfo] systemUptime];
    self.appStartTimeBottom = [self uptime];
}

- (void)refreshDataForCountDown{
    if (!self.timer) {
        __weak typeof(self) weakSelf = self;
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC, 0.0f * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timer, ^{
            
            @autoreleasepool {
                NSLog(@"定期器跑起来了。。。");
                NSTimeInterval timerTop = ([[NSProcessInfo processInfo] systemUptime] - weakSelf.appStartTimeTop);
                NSTimeInterval timerBottom = ([weakSelf uptime] - weakSelf.appStartTimeBottom);
                
                
                weakSelf.topLabel.text = [weakSelf.formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:weakSelf.serverTimeTop + timerTop]];
                weakSelf.bottomLabel.text = [weakSelf.formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:weakSelf.serverTimeBottom + timerBottom]];
                
                
            }
        });
        dispatch_resume(self.timer);
    }
}

- (NSTimeInterval)uptime
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    
    struct timeval now;
    struct timezone tz;
    gettimeofday(&now, &tz);
    
    double uptime = -1;
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now.tv_sec - boottime.tv_sec;
        uptime += (double)(now.tv_usec - boottime.tv_usec) / 1000000.0;
    }
    return uptime;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
