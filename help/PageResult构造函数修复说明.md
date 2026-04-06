# PageResult 构造函数参数顺序修复说明

## 问题描述

编译时出现以下错误：
```
[ERROR] ChatMessageService.java:[56,16] 无法推断com.csi.help.common.PageResult<>的类型参数
[ERROR] CommunityService.java:[34,16] 无法推断com.csi.help.common.PageResult<>的类型参数
```

## 问题原因

`PageResult` 类的构造函数参数顺序为：
```java
public PageResult(List<T> items, Long total, Integer page, Integer pageSize)
```

但在 `ChatMessageService` 和 `CommunityService` 中使用了错误的参数顺序：
```java
// 错误的调用方式
return new PageResult<>(total, messages);  // 参数顺序错误
```

## 修复方案

### 1. ChatMessageService.java (第 56 行)

**修复前：**
```java
return new PageResult<>(total, messages);
```

**修复后：**
```java
return new PageResult<>(messages, total, page, pageSize);
```

### 2. CommunityService.java (第 34 行)

**修复前：**
```java
return new PageResult<>(total, requests);
```

**修复后：**
```java
return new PageResult<>(requests, total, page, pageSize);
```

## 验证结果

修复后执行 `mvnw.cmd clean compile`，编译成功：
```
[INFO] BUILD SUCCESS
[INFO] Total time:  3.800 s
```

## 相关文件

- `help/src/main/java/com/csi/help/common/PageResult.java` - PageResult 类定义
- `help/src/main/java/com/csi/help/service/ChatMessageService.java` - 聊天消息服务
- `help/src/main/java/com/csi/help/service/CommunityService.java` - 社区管理服务
- `help/src/main/java/com/csi/help/service/HelpRequestService.java` - 求助请求服务（已正确使用）

## 注意事项

所有使用 `PageResult` 构造函数的地方都应该遵循正确的参数顺序：
```java
new PageResult<>(items, total, page, pageSize)
```

其中：
- `items`: 数据列表 (List<T>)
- `total`: 总记录数 (Long)
- `page`: 当前页码 (Integer)
- `pageSize`: 每页大小 (Integer)
