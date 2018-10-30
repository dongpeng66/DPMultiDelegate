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



