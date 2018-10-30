//
//  ViewController.m
//  DPMultiDelegate
//
//  Created by jxchain on 2018/10/30.
//  Copyright © 2018 jxchain. All rights reserved.
//

#import "ViewController.h"
#import "DPThemesManager.h"
@interface ViewController ()<DPThemesManagerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[DPThemesManager sharedManager]addDelegate:self];
    self.view.backgroundColor = [DPThemesManager sharedManager].themesColor;
    
    
    
    
    UIButton *btn=[[UIButton alloc]initWithFrame:CGRectMake(15, 200, self.view.frame.size.width-30, 44)];
    [btn setTitle:@"换肤" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor=[UIColor orangeColor];
    [btn addTarget:self action:@selector(btnDidClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    
    
}
#pragma mark-按钮的点击事件
-(void)btnDidClick{
    [DPThemesManager sharedManager].themesColor=[self randomColor];
}
- (UIColor *)randomColor {
    // 生成随机颜色
    CGFloat hue = arc4random() % 100 / 100.0; //色调：0.0 ~ 1.0
    CGFloat saturation = (arc4random() % 50 / 100) + 0.5; //饱和度：0.5 ~ 1.0
    CGFloat brightness = (arc4random() % 50 / 100) + 0.5; //亮度：0.5 ~ 1.0
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}
#pragma mark - DPThemesManagerDelegate
- (void)themesColorChanged:(UIColor *)themesColor{
    // 需要注意的是这里是异步调用，改变颜色需要在主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.backgroundColor = themesColor;
    });
}

@end
