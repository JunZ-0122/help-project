# Help System - 互助帮扶系统后端

## 📖 项目简介

Help System 是一个为老年人和残障人士提供互助服务的平台后端系统。采用 Spring Boot + MyBatis + MySQL 技术栈，实现了完整的三层架构。

## ✨ 核心功能

- 🔐 用户认证与授权（JWT）
- 📝 求助请求管理
- 👥 志愿者订单管理
- 💬 实时聊天系统
- ⭐ 评价与反馈
- 👤 用户信息管理
- 🏘️ 社区管理功能

## 🚀 快速开始

### 环境要求
- JDK 17+
- Maven 3.6+
- MySQL 8.0+

### 启动步骤

1. **创建数据库**
```sql
CREATE DATABASE help CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. **初始化数据**
```bash
mysql -u root -p help < src/main/resources/schema.sql
mysql -u root -p help < src/main/resources/test-data.sql
```

3. **配置应用**
编辑 `src/main/resources/application.yml`，修改数据库连接信息。

4. **启动项目**
```bash
mvn spring-boot:run
```

5. **访问测试**
访问 http://localhost:8080

详细步骤请查看 [快速启动指南](./快速启动指南.md)

## 📚 文档导航

### 核心文档
- [📋 后端项目结构说明](./后端项目结构说明.md) - 项目架构和代码结构
- [📖 API 接口文档](./API接口文档.md) - 完整的 API 接口说明（32个接口）
- [🚀 快速启动指南](./快速启动指南.md) - 环境配置和启动步骤
- [✅ 后端开发完成总结](./后端开发完成总结.md) - 项目完成情况总结

### 前端对接文档
- [前端开发总结_后端对接文档](../help_system/前端开发总结_后端对接文档.md)
- [API 接口清单](../help_system/API接口清单.md)
- [后端开发快速参考](../help_system/后端开发快速参考.md)
- [文档索引_后端开发专用](../help_system/文档索引_后端开发专用.md)

## 🏗️ 技术架构

### 技术栈
- **框架**: Spring Boot 3.5.11
- **ORM**: MyBatis 3.0.5
- **数据库**: MySQL 8.0+
- **认证**: JWT (JSON Web Token)
- **工具**: Lombok, Hutool

### 三层架构
```
Controller 层 → Service 层 → Mapper 层
    ↓              ↓             ↓
  HTTP请求      业务逻辑      数据访问
```

## 📊 项目统计

- **代码文件**: 33 个 Java 类
- **API 接口**: 32 个 RESTful 接口
- **数据库表**: 5 个核心表
- **功能模块**: 7 个业务模块

## 🧪 测试账号

| 角色 | 手机号 | 密码 | 说明 |
|------|--------|------|------|
| 求助者 | 13800138001 | 123456 | 张大爷，65岁 |
| 志愿者 | 13800138002 | 123456 | 李小明，25岁 |
| 社区管理员 | 13800138003 | 123456 | 王经理 |

## 📡 API 示例

### 用户登录
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138001",
    "password": "123456"
  }'
```

### 创建求助请求
```bash
curl -X POST http://localhost:8080/api/help-requests/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "需要帮助购买日用品",
    "description": "因行动不便，需要帮忙购买一些日用品",
    "type": "daily-care",
    "urgency": "normal",
    "location": "北京市朝阳区XX小区",
    "contactPhone": "13800138000"
  }'
```

更多接口示例请查看 [API 接口文档](./API接口文档.md)

## 🗂️ 项目结构

```
help/
├── src/main/
│   ├── java/com/csi/help/
│   │   ├── HelpApplication.java          # 启动类
│   │   ├── common/                       # 通用类
│   │   ├── config/                       # 配置类
│   │   ├── controller/                   # 控制器（7个）
│   │   ├── dto/                          # 数据传输对象
│   │   ├── entity/                       # 实体类（5个）
│   │   ├── exception/                    # 异常处理
│   │   ├── interceptor/                  # 拦截器
│   │   ├── mapper/                       # Mapper接口（5个）
│   │   ├── service/                      # 服务层（7个）
│   │   └── util/                         # 工具类
│   └── resources/
│       ├── mapper/                       # MyBatis XML（5个）
│       ├── application.yml               # 应用配置
│       ├── schema.sql                    # 数据库结构
│       └── test-data.sql                 # 测试数据
├── pom.xml                               # Maven配置
└── 文档/                                 # 项目文档
```

## 🔧 常见问题

### Q: 如何修改端口号？
A: 编辑 `application.yml`，修改 `server.port` 配置。

### Q: 如何查看 SQL 日志？
A: 在 `application.yml` 中设置：
```yaml
logging:
  level:
    com.csi.help.mapper: DEBUG
```

### Q: Token 过期怎么办？
A: 使用刷新 Token 接口 `POST /api/auth/refresh` 获取新的 Token。

### Q: 如何添加新的接口？
A: 按照三层架构：Entity → Mapper → Service → Controller 的顺序开发。

更多问题请查看 [快速启动指南](./快速启动指南.md)

## 📈 开发进度

- ✅ 用户认证模块
- ✅ 求助请求模块
- ✅ 志愿者订单模块
- ✅ 聊天消息模块
- ✅ 评价模块
- ✅ 用户管理模块
- ✅ 社区管理模块
- ✅ 全局异常处理
- ✅ 数据库设计
- ✅ 测试数据
- ✅ 完整文档

**所有核心功能已完成！可以开始前后端联调。**

## 🎯 下一步计划

### 可选增强功能
- [ ] WebSocket 实时通信
- [ ] 文件上传服务
- [ ] 短信验证码服务
- [ ] Redis 缓存集成
- [ ] 消息推送服务

## 📞 技术支持

如有问题，请查看：
1. [项目文档](#-文档导航)
2. [API 接口文档](./API接口文档.md)
3. [快速启动指南](./快速启动指南.md)

## 📄 许可证

本项目仅供学习和研究使用。

---

**项目状态**: ✅ 开发完成  
**最后更新**: 2024-03-07  
**版本**: v1.0
