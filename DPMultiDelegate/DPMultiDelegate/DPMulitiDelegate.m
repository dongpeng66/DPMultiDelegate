//
//  DPMulitiDelegate.m
//  DPMultiDelegate
//
//  Created by jxchain on 2018/10/30.
//  Copyright © 2018 jxchain. All rights reserved.
//

#import "DPMulitiDelegate.h"
@interface DPMulitiDelegate ()
@property (nonatomic,strong) dispatch_semaphore_t semaphore;
@property (nonatomic,strong) NSHashTable *delegates;;
@end
@implementation DPMulitiDelegate
//初始化
+(id)alloc{
    DPMulitiDelegate *instance=[super alloc];
    if (instance) {
        instance.semaphore=dispatch_semaphore_create(1);
        instance.delegates=[NSHashTable weakObjectsHashTable];
    }
    return instance;
}
+(instancetype)share{
    return [DPMulitiDelegate alloc];
}
//添加代理
-(void)addDelegate:(id)delegate{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_delegates addObject:delegate];
    dispatch_semaphore_signal(_semaphore);
}
//移除代理
-(void)removeDelete:(id)delegate{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_delegates removeObject:delegate];
    dispatch_semaphore_signal(_semaphore);
}
//消息转发
#pragma mark-消息转发
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    NSMethodSignature *methodSignature;
    for (id delegate in _delegates) {
        if ([delegate respondsToSelector:selector]) {
            methodSignature = [delegate methodSignatureForSelector:selector];
            break;
        }
    }
    dispatch_semaphore_signal(_semaphore);
    dispatch_semaphore_signal(_semaphore);
    if (methodSignature) {
        return methodSignature;
    }
    //未找到方法时，返回默认方法"-(void)method",防止崩溃
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
}
-(void)forwardInvocation:(NSInvocation *)invocation{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    // 为了避免造成递归死锁，copy一份delegates而不是直接用信号量将for循环包裹
    
    NSHashTable *copyDelegates = [_delegates copy];
    
    dispatch_semaphore_signal(_semaphore);
    
    SEL selector = invocation.selector;
    for (id delegate in copyDelegates) {
        if ([delegate respondsToSelector:selector]) {
            // 异步调用时，拷贝一个Invocation，以免意外修改target导致crash
            NSInvocation *dupInvocation = [self copyInvocation:invocation];
            dupInvocation.target = delegate;
            // 异步调用多代理方法，以免响应不及时
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [dupInvocation invoke];
            });
        }
    }
}
- (NSInvocation *)copyInvocation:(NSInvocation *)invocation {
    SEL selector = invocation.selector;
    NSMethodSignature *methodSignature = invocation.methodSignature;
    NSInvocation *copyInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    copyInvocation.selector = selector;
    
    NSUInteger count = methodSignature.numberOfArguments;
    for (NSUInteger i = 2; i < count; i++) {
        void *value;
        [invocation getArgument:&value atIndex:i];
        [copyInvocation setArgument:&value atIndex:i];
    }
    [copyInvocation retainArguments];
    return copyInvocation;
}
@end
