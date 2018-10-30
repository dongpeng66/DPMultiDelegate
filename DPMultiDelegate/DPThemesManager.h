//
//  DPThemesManager.h
//  DPMultiDelegate
//
//  Created by jxchain on 2018/10/30.
//  Copyright © 2018 jxchain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol DPThemesManagerDelegate <NSObject>

/// 主题颜色改变
- (void)themesColorChanged:(UIColor *)themesColor;
@end

NS_ASSUME_NONNULL_BEGIN

@interface DPThemesManager : NSObject
/// 主题颜色
@property ( nonatomic, copy ) UIColor *themesColor;

/// 获取单例
+ (instancetype)sharedManager;

/// 添加、移除代理
- (void)addDelegate:(id<DPThemesManagerDelegate>)delegate;
- (void)removeDelegate:(id<DPThemesManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
