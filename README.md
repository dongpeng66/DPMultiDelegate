# DPMultiDelegate OC 多播代理
## 类与类之间的通信我们有很多种方式，iOS中有代理，通知，block，单例类等等，每种方式都有其适用的场景
假设委托者皇上发起一个委托事件 要吃饭，这个事件的参数是今天要吃红烧肉，水煮鱼，肉末茄子，最终做饭这件事会被代理者实施，厨师甲做红烧肉，厨师乙做水煮鱼，厨师丙做肉末茄子

```
在iOS开发中面对上面这个需求，我们肯定能想到用通知模式来实现这个逻辑。其实更好的做法是使用多播代理模式
```

* 用通知的方式实现：用大喇叭广播：“皇上要吃饭了，并且要吃红烧肉，水煮鱼，肉末茄子”，虽然厨师甲乙丙听到之后就会开始去做给皇上做菜，但是这广播出去全城的人都知道了，这种消息传递方式会造成消息外露，不受控制；
* 用多播代理的方式实现：皇上通过吃饭总管告诉厨师甲乙丙它要吃饭了，甲乙丙收到消息后就去给皇上做菜了，这种消息传递很精准，并且不会导致消息外露。

## 一. 为什么不用通知
通知是一种零耦合的类之间通信方式，它的优点就是能够完全解耦，然而除了这个优点，通知也有不少值得吐槽的地方：

* 通知的接收范围为全局，这可能会暴露你原本想隐藏的实现细节，比如你封装的SDK中发出的通知，通知参数中包含敏感信息等；
* 通知的匹配完全依赖字符串，容易出现问题，当项目中大量使用通知以后难以维护，极端情况会出现通知名重复的问题；
* 相对于代理方式，通知不能像代理一样使用协议来约束代理者的方法实现；
* 通知携带的参数不能直观的表达出来，依靠字典操作也增加的出错的可能性，通知不能像代理方法那样有返回值；
* 通知参数传递对于基本类型需要装箱和拆箱操作，不能传递nil参数；
* 通知有时候会打破高内聚低耦合中的高内聚的原则，对于原本就有单向依赖的2个类来说，他们是有内聚耦合关系的，使用通知反而将这种内聚关系打散了，并且不利于方法调试；

## 二.多播代理
C#中有一种委托形式称作多播委托，会顺序执行多个委托对象的对应函数。 OC中系统并没有提供类似的类型让我们使用，所以需要自己实现类似的功能。
</br>
![图片名称](https://github.com/dongpeng66/DPMultiDelegate/blob/master/1.png)
## 三.多播代理的实现思路
### 1.多播代理的实现思路
OC中常规代理通常使用弱引用来避免循环引用，因此我们的多播代理中也需要使用能够存储弱引用对象的容器，这里有几种思路：

* 使用NSValue的valueWithNonretainedObject:方法将对象打包，然后将打包后的NSValue对象添加到代理数组中。
* 创建一个新的类，在这个类中对代理对象进行弱引用（实质是对上一个思路的手动实现）。然后再将这个新类的实例添加到代理数组中。
* 使用NSHashTable存储代理对象，我们用到一个比较不常见的容器：NSHashTable


### NSHashTable
iOS6以后，Foundation框架中新增了容器类：NSHashTable —— 它是可变的，没有一个不变的类与其对应。它的作用对应于NSMutableSet，但是它可以通过设置NSPointerFunctionsOptions参数来指定对象的引用类型：

```
NSHashTableStrongMemory：将容器内的对象引用计数+1一次(即strong)
NSHashTableCopyIn：将添加到容器的对象通过NSCopying中的方法，复制一个新的对象存入容器(即copy)
NSHashTableZeroingWeakMemory：使用weak存储对象，当对象被销毁的时候自动将其从集合中移除。(已弃用)
NSHashTableObjectPointerPersonality： 使用移位指针(shifted pointer)来做hash检测及确定两个对象是否相等(而不是使用NSObject中的hash方法)
NSHashTableWeakMemory：不会修改容器内对象元素的引用计数，并且对象释放后，会被自动移除(即weak)

```

```
ps NSHashTableWeakMemory的对象释放后，NSHashTable中其实是置空（NSHashTable可以保存空对象），但遍历时不会遍历到该对象，相对于移除了。
```

### 2.添加代理对象

基于上面的选择，我们使用 NSHashTable 来管理存储和遍历代理对象，因此需要公开一个添加代理的方法：
```
- (void)addDelegate:(id <xxxProtocol>)newDelegate;
```

### 3.调用代理方法

调用常规代理时，通常需要写以下写法：
```
if ([delegate respondsToSelector:@selector(<#方法名#>:)]) {
    [delegate <#方法名#>:<#参数#>];
}
```

那么假如我们的代理协议中有多个方法，我们就需要对每个代理方法都写一次这样的代码，相当繁琐。 通常的简化方法是利用OC的消息转发机制，在方法转发过程中进行消息转发。

## 具体实现

### 1. 定义多代理转发类

这个类用来封装多代理实现，我们使用NSProxy子类来实现它：

```
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
```

### 2. 处理多线程同步问题

使用信号量解决多线程集合对象的同步问题:
```
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
```
### 简单使用，例如用来更换皮肤
```
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
```

```
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
```


```
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
```
