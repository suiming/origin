//
//  ExposeTimer.m
//  PetersLab
//
//  Created by suiming on 2021/11/20.
//

#import "ExposeTimer.h"

@interface ExposeTimer ()

@property(nonatomic, strong) NSTimer *timer;

@property(nonatomic, strong)dispatch_queue_t seriralQueue;

@property(nonatomic, strong)dispatch_queue_t concurrent;

@end



@implementation ExposeTimer

// 在一个串行队列执行Timer
- (void)beginLoop {
    self.seriralQueue = dispatch_queue_create("ExposeTimerQueue", DISPATCH_QUEUE_SERIAL);
    self.concurrent = dispatch_queue_create("ExposeOperation", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(self.seriralQueue, ^{
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)stopLoop {
    [self.timer invalidate];
    self.timer = nil;
}

-(NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(loopOnce) userInfo:nil repeats:YES];
    }
    return _timer;
}

// 在多线程上执行具体操作
- (void)loopOnce {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = [self getCurrentVC];
        NSString *pageName = NSStringFromClass([viewController class]);
        
        dispatch_async(self.concurrent, ^{
            [ExposeDataManager.sharedInstance loopUnsafeComponentsForPageName:pageName];
        });
    });
    
    
}

- (UIViewController *)getCurrentVC {
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    UIViewController * nextResponder = window.rootViewController;
    result = [self getCurrentVisibleVC:nextResponder];
    
    return result;
}


- (UIViewController *)getCurrentVisibleVC:(id)nextResponder {
    
    UIViewController *result = nil;
    if ([nextResponder isKindOfClass:[UITabBarController class]]) {
        UITabBarController * nextVc = (UITabBarController *)nextResponder;
        nextResponder = nextVc.viewControllers[nextVc.selectedIndex];
         result =  [self getCurrentVisibleVC:nextResponder];
        
    } else if([nextResponder isKindOfClass:[UINavigationController class]]) {
        UINavigationController * Navi = (UINavigationController *)nextResponder;
        result = Navi.visibleViewController;
        if (result) result = [self getCurrentVisibleVC:result];
    }
    else if ([nextResponder isKindOfClass:[UIViewController class]]) {
        result = nextResponder;
    }
    
    return result ?: nextResponder;
}



@end