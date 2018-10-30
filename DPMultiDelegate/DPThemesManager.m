//
//  DPThemesManager.m
//  DPMultiDelegate
//
//  Created by jxchain on 2018/10/30.
//  Copyright © 2018 jxchain. All rights reserved.
//

#import "DPThemesManager.h"
#import "DPMulitiDelegate.h"
@interface DPThemesManager()

/// 多播代理
@property ( nonatomic, strong ) DPMulitiDelegate *delegateProxy;

@end
@implementation DPThemesManager
@synthesize themesColor = _themesColor;
static DPThemesManager *_manager = nil;
+ (instancetype)sharedManager{
    return [[self alloc]init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_manager == nil) {
            _manager = [super allocWithZone:zone];
        }
    });
    return _manager;
}
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return _manager;
}

- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    return _manager;
}

- (DPMulitiDelegate *)delegateProxy{
    if (!_delegateProxy) {
        _delegateProxy = [DPMulitiDelegate share];
    }
    return _delegateProxy;
}

- (void)addDelegate:(id<DPThemesManagerDelegate>)delegate {
    [self.delegateProxy addDelegate:delegate];
}

- (void)removeDelegate:(id<DPThemesManagerDelegate>)delegate {
    [self.delegateProxy removeDelete:delegate];
}

- (void)setThemesColor:(UIColor *)themesColor{
    _themesColor = [themesColor copy];
    [(id<DPThemesManagerDelegate>)self.delegateProxy themesColorChanged:_themesColor];
}

- (UIColor *)themesColor{
    if (!_themesColor) {
        // 默认颜色
        _themesColor = [UIColor colorWithWhite:0.8f alpha:1.f];
    }
    return _themesColor;
}

@end
