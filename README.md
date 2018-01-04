#SQNetwork

### 介绍：

SQNetwork 是针对 [AFNetworking](https://github.com/AFNetworking/AFNetworking) 的二次封装，在 [YTKNetwork](https://github.com/yuantiku/YTKNetwork) 的基础上进行的修改。


### 结构：

项目逻辑结构大致如下：
```
    .
    ├── SQNetwork：Public 头文件
    │   ├── SQRequest：网络 API 抽象基类，所有自定义 API 都要继承此类
    │   │   ├── SQNetworkAgent：底层对 AFN 封装的工具类，负责网络的实际请求
    │   │   ├── SQNetworkCache：缓存
    │   │   └── SQNetworkPrivate：私有接口文件
    │   ├── SQGeneralRequest：通用 API
    │   ├── SQBatchRequest：多 API 组合请求
    │   │   └── SQBatchRequestAgent：SQBatchRequest 实例内存引用集合
    │   └── SQNetworkConfig：全局公共的 API 配置

    
```

### 基本思想：

- SQNetwork 是基于 YTKNetwork 设计思想的改进，每个网络请求都被封装成一个对象。所以，你的每一个请求都需要继承 `SQRequest` 类，通过实现 `SQRequest` 协议定义的一些方法来构造配置指定的网络请求。

- 在文件`SQRequest.h`中，定义了几个协议来丰富网络请求的处理：

	* `SQRequestAccessory`，网络请求附件协议。通过`-addAccessory:`添加附件。网络请求会在发起、着陆时对每个附件进行回调，因此，附件可以通过这些回调做些自定义的操作，比如添加 loading 等。
	* `SQRequestFormatter`，数据格式化协议。通过设定代理`dataFormatter`来指定特定的 fromatter，从而实现请求原始数据到特定 modle 的转化。并且，提供了异步线程、主线程两种回调。
		```
		// 如果同时实现这两个方法，第二个方法的返回值会覆盖第一个方法
		- (nullable id)formattedDataAfterRequestCompletePreprocessor:(__kindof SQRequest *)request;
		
		- (nullable id)formattedDataAfterRequestCompleteFilter:(__kindof SQRequest *)request

		```
	
		> 为什么`SQRequest`要单独提供数据格式化回调，而不是全都交给使用者呢？这里提供统一的回调，可以使请求任务分工更加明确，回调更统一。同时，每个 API 可以指定不同的`dataFormatter`，维护也更方便。
	* `SQRequestDelegate`，请求任务完成协议。这个协议定义了请求完成的回调方法，并且单独提供格式化数据的回调。一旦实现了请求的自定义格式化，请求成功后会回调下面的方法：
	  ```
	  - (void)request:(__kindof SQRequest *)request finishedWithFormattedResponse:(nullable id)response
	  ```
	  而没有做数据格式化的请求，成功后的回调如下：
	  ```objc
	  - (void)requestFinished:(__kindof SQRequest *)request
	  ```
	  这样将网络请求区分回调，可以让回调更加清晰明确。
	  
	* `SQRequest`，请求配置协议。

		> 这里采用了协议的方式，为什么没有像`YTKNetwork`那样采用子类继承重写的方式呢？这里，主要考虑继承方式的 API 在设计上，子类的实现是不确定的。作为基类，就应该约束规则，保证子类完全遵循。因此，`SQRequest`在内部也对子类做了约束处理。

### 使用:

- 创建新的 API 类，继承自`SQRequest`，并遵循协议`SQRequest`，实现协议定义的方法完成配置，然后发起请求、接受回调。

- 对于比较简单的 API，单独建个类可能会有些多余，同时导致类过多的爆炸（离散式 API 的缺点，因此离散式 API 更适合模块化、复杂的请求）。所以，提供了`SQGeneralRequest`，并通过属性完成简单的配置，然后发起请求。

- `SQNetworkConfig`提供了全局的请求配置，在这里可以添加实现协议 `SQUrlFilterProtocol` 的自定义 url filter，来实现全局请求的基础、公共配置等。


### 引用：
- casatwy 大神的博客[iOS应用架构谈 网络层设计方案
](https://casatwy.com/iosying-yong-jia-gou-tan-wang-luo-ceng-she-ji-fang-an.html)

- 饿了么[HTTP/2下的iOS网络层架构设计
](https://www.jianshu.com/p/a9bca62d8dab)

- 猿题库开源网络库[YTKNetwork](https://github.com/yuantiku/YTKNetwork)



