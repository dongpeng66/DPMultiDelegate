//
//  DPMulitiDelegate.h
//  DPMultiDelegate
//
//  Created by jxchain on 2018/10/30.
//  Copyright © 2018 jxchain. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DPMulitiDelegate : NSProxy
/**
 创建
 @return DPMulitiDelegate对象
 */
+ (instancetype)share;
/**
 添加代理
 */
- (void)addDelegate:(id)delegate;
/**
 移除代理
 */
- (void)removeDelete:(id)delegate;
@end

NS_ASSUME_NONNULL_END
