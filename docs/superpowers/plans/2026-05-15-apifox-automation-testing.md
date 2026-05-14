# Apifox Automation Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add OpenAPI export support to `help` and produce a concrete Apifox import and automation testing guide for local use.

**Architecture:** First lock the OpenAPI metadata and bearer security scheme with unit tests, then add the `springdoc` dependency and configuration. Next lock controller-level documentation annotations with reflection-based tests, then annotate every live controller route. Finally add a human-facing Apifox onboarding guide and verify the exported JSON and Swagger UI endpoints locally.

**Tech Stack:** Spring Boot 3.5.11, springdoc-openapi 2.8.17, JUnit 5, Mockito, Maven, PowerShell

---

## File Structure

- Modify: `help/pom.xml`
  - Add the `springdoc-openapi-starter-webmvc-ui` dependency.
- Create: `help/src/main/java/com/csi/help/config/OpenApiConfig.java`
  - Define the `OpenAPI` bean and bearer security scheme.
- Modify: `help/src/main/java/com/csi/help/config/WebConfig.java`
  - Explicitly allow `swagger-ui` and `api-docs` paths.
- Modify: `help/src/main/java/com/csi/help/controller/AuthController.java`
  - Add `@Tag` and `@Operation` for auth endpoints.
- Modify: `help/src/main/java/com/csi/help/controller/GeocodeController.java`
  - Add `@Tag` and `@Operation` for reverse geocoding.
- Modify: `help/src/main/java/com/csi/help/controller/HelpRequestController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/VolunteerOrderController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/ChatMessageController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/CommunityController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/UserController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/VolunteerController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/ReviewController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Modify: `help/src/main/java/com/csi/help/controller/EmergencyController.java`
  - Add `@Tag`, `@SecurityRequirement`, and `@Operation`.
- Create: `help/src/test/java/com/csi/help/config/OpenApiConfigTest.java`
  - Lock OpenAPI metadata and bearer scheme behavior.
- Create: `help/src/test/java/com/csi/help/controller/OpenApiAnnotationsTest.java`
  - Lock `@Tag`, `@Operation`, and protected-controller security declarations.
- Create: `help/APIFOX_AUTOMATION_GUIDE.md`
  - Document Apifox import URL, env vars, test collections, and scripts.

### Task 1: Lock the OpenAPI configuration contract

**Files:**
- Modify: `help/pom.xml`
- Create: `help/src/main/java/com/csi/help/config/OpenApiConfig.java`
- Create: `help/src/test/java/com/csi/help/config/OpenApiConfigTest.java`

- [ ] **Step 1: Write the failing test for metadata and bearer security**

```java
package com.csi.help.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class OpenApiConfigTest {

    @Test
    void buildsOpenApiMetadataForApifoxImport() {
        OpenApiConfig config = new OpenApiConfig();

        OpenAPI openAPI = config.helpOpenApi();

        assertEquals("Help System API", openAPI.getInfo().getTitle());
        assertEquals("v1", openAPI.getInfo().getVersion());
        assertEquals("OpenAPI description for Apifox import and local automation testing.", openAPI.getInfo().getDescription());
    }

    @Test
    void registersBearerSecurityScheme() {
        OpenApiConfig config = new OpenApiConfig();

        OpenAPI openAPI = config.helpOpenApi();
        SecurityScheme securityScheme = openAPI.getComponents()
                .getSecuritySchemes()
                .get(OpenApiConfig.SECURITY_SCHEME_NAME);

        assertNotNull(securityScheme);
        assertEquals(SecurityScheme.Type.HTTP, securityScheme.getType());
        assertEquals("bearer", securityScheme.getScheme());
        assertEquals("JWT", securityScheme.getBearerFormat());
        assertEquals("Authorization", securityScheme.getName());
        assertEquals(OpenApiConfig.SECURITY_SCHEME_NAME, openAPI.getSecurity().get(0).keySet().iterator().next());
    }
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help
mvn "-Dtest=OpenApiConfigTest" test
```

Expected: FAIL because the `springdoc-openapi` dependency and `OpenApiConfig.java` do not exist yet.

- [ ] **Step 3: Add the dependency and the minimal OpenAPI configuration**

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.8.17</version>
</dependency>
```

```java
package com.csi.help.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    public static final String SECURITY_SCHEME_NAME = "bearerAuth";

    @Bean
    public OpenAPI helpOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Help System API")
                        .version("v1")
                        .description("OpenAPI description for Apifox import and local automation testing."))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME, new SecurityScheme()
                                .name("Authorization")
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME));
    }
}
```

- [ ] **Step 4: Re-run the test and confirm it passes**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help
mvn "-Dtest=OpenApiConfigTest" test
```

Expected: `OpenApiConfigTest` PASS.

- [ ] **Step 5: Commit**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help/pom.xml help/src/main/java/com/csi/help/config/OpenApiConfig.java help/src/test/java/com/csi/help/config/OpenApiConfigTest.java
git commit -m "feat: add OpenAPI configuration for Apifox import"
```

### Task 2: Lock and implement controller-level documentation annotations

**Files:**
- Create: `help/src/test/java/com/csi/help/controller/OpenApiAnnotationsTest.java`
- Modify: `help/src/main/java/com/csi/help/config/WebConfig.java`
- Modify: `help/src/main/java/com/csi/help/controller/AuthController.java`
- Modify: `help/src/main/java/com/csi/help/controller/GeocodeController.java`
- Modify: `help/src/main/java/com/csi/help/controller/HelpRequestController.java`
- Modify: `help/src/main/java/com/csi/help/controller/VolunteerOrderController.java`
- Modify: `help/src/main/java/com/csi/help/controller/ChatMessageController.java`
- Modify: `help/src/main/java/com/csi/help/controller/CommunityController.java`
- Modify: `help/src/main/java/com/csi/help/controller/UserController.java`
- Modify: `help/src/main/java/com/csi/help/controller/VolunteerController.java`
- Modify: `help/src/main/java/com/csi/help/controller/ReviewController.java`
- Modify: `help/src/main/java/com/csi/help/controller/EmergencyController.java`

- [ ] **Step 1: Write the failing reflection test**

```java
package com.csi.help.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;

import java.lang.reflect.Method;
import java.util.List;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class OpenApiAnnotationsTest {

    private static final List<Class<?>> PUBLIC_CONTROLLERS = List.of(
            AuthController.class,
            GeocodeController.class
    );

    private static final List<Class<?>> PROTECTED_CONTROLLERS = List.of(
            ChatMessageController.class,
            CommunityController.class,
            EmergencyController.class,
            HelpRequestController.class,
            ReviewController.class,
            UserController.class,
            VolunteerController.class,
            VolunteerOrderController.class
    );

    @Test
    void everyControllerDeclaresATag() {
        Stream.concat(PUBLIC_CONTROLLERS.stream(), PROTECTED_CONTROLLERS.stream()).forEach(controller -> {
            Tag tag = controller.getAnnotation(Tag.class);
            assertNotNull(tag, controller.getSimpleName() + " is missing @Tag");
            assertFalse(tag.name().isBlank(), controller.getSimpleName() + " tag name should not be blank");
        });
    }

    @Test
    void protectedControllersDeclareBearerSecurity() {
        PROTECTED_CONTROLLERS.forEach(controller -> {
            SecurityRequirement securityRequirement = controller.getAnnotation(SecurityRequirement.class);
            assertNotNull(securityRequirement, controller.getSimpleName() + " is missing @SecurityRequirement");
            assertEquals("bearerAuth", securityRequirement.name());
        });
    }

    @Test
    void everyMappedMethodHasNonBlankSummary() {
        Stream.concat(PUBLIC_CONTROLLERS.stream(), PROTECTED_CONTROLLERS.stream()).forEach(controller -> {
            for (Method method : controller.getDeclaredMethods()) {
                if (hasHttpMapping(method)) {
                    Operation operation = method.getAnnotation(Operation.class);
                    assertNotNull(operation, controller.getSimpleName() + "#" + method.getName() + " is missing @Operation");
                    assertFalse(operation.summary().isBlank(), controller.getSimpleName() + "#" + method.getName() + " summary should not be blank");
                }
            }
        });
    }

    private boolean hasHttpMapping(Method method) {
        return method.isAnnotationPresent(GetMapping.class)
                || method.isAnnotationPresent(PostMapping.class)
                || method.isAnnotationPresent(PutMapping.class)
                || method.isAnnotationPresent(DeleteMapping.class);
    }
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help
mvn "-Dtest=OpenApiAnnotationsTest" test
```

Expected: FAIL because controllers are missing `@Tag`, mapped methods are missing `@Operation`, and protected controllers are missing `@SecurityRequirement`.

- [ ] **Step 3: Add the route annotations and whitelist the doc endpoints**

```java
// WebConfig.java
registry.addInterceptor(authInterceptor)
        .addPathPatterns("/api/**")
        .excludePathPatterns(
                "/api/auth/login",
                "/api/auth/register",
                "/api/auth/send-code",
                "/api/auth/refresh-token",
                "/api/geocode/regeo",
                "/v3/api-docs",
                "/v3/api-docs/**",
                "/swagger-ui.html",
                "/swagger-ui/**"
        );
```

```java
// AuthController.java
@Tag(name = "认证")
public class AuthController {

    @Operation(summary = "用户登录")
    public Result<LoginResponse> login(@Validated @RequestBody LoginRequest request)

    @Operation(summary = "用户注册")
    public Result<LoginResponse> register(@Validated @RequestBody RegisterRequest request)

    @Operation(summary = "发送验证码")
    public Result<SendCodeResponse> sendCode(@RequestBody Map<String, String> request)

    @Operation(summary = "刷新访问令牌")
    public Result<LoginResponse> refreshToken(@RequestBody Map<String, String> request)

    @Operation(summary = "退出登录")
    public Result<Void> logout()
}

// GeocodeController.java
@Tag(name = "地理编码")
public class GeocodeController {

    @Operation(summary = "经纬度逆地理编码")
    public Result<Map<String, String>> regeo(@RequestParam double latitude, @RequestParam double longitude)
}
```

```java
// HelpRequestController.java
@Tag(name = "求助请求")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class HelpRequestController {

    @Operation(summary = "获取求助列表")
    public Result<PageResult<HelpRequest>> getRequests(@RequestParam(required = false) String type, @RequestParam(required = false) String status, @RequestParam(required = false) String urgency, @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "10") Integer pageSize)

    @Operation(summary = "创建求助请求")
    public Result<HelpRequest> create(@RequestBody HelpRequest request, @RequestAttribute String userId, @RequestAttribute String userName, @RequestAttribute String userPhone)

    @Operation(summary = "获取手表端求助状态")
    public Result<WatchRequestStatusDto> getWatchStatus(@PathVariable String id, @RequestAttribute String userId)

    @Operation(summary = "推进开发调试流转")
    public Result<Void> startDevFlow(@PathVariable String id, @RequestAttribute String userId)

    @Operation(summary = "获取求助者详情聚合视图")
    public Result<SeekerRequestDetailVo> getSeekerDetail(@PathVariable String id, @RequestAttribute String userId)

    @Operation(summary = "获取求助详情")
    public Result<HelpRequest> getById(@PathVariable String id)

    @Operation(summary = "更新求助请求")
    public Result<HelpRequest> update(@PathVariable String id, @RequestBody HelpRequest request)

    @Operation(summary = "取消求助请求")
    public Result<Void> delete(@PathVariable String id)

    @Operation(summary = "获取我的求助列表")
    public Result<PageResult<HelpRequest>> getMyRequests(@RequestAttribute String userId, @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "10") Integer pageSize)

    @Operation(summary = "获取我的最近求助")
    public Result<List<HelpRequest>> getRecentMyRequests(@RequestAttribute String userId, @RequestParam(defaultValue = "3") Integer limit)
}

// VolunteerOrderController.java
@Tag(name = "志愿者订单")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class VolunteerOrderController {

    @Operation(summary = "志愿者接单")
    public Result<VolunteerOrder> acceptOrder(@RequestBody Map<String, String> params, @RequestAttribute("userId") String volunteerId)

    @Operation(summary = "获取我的订单列表")
    public Result<?> getMyOrders(@RequestAttribute("userId") String volunteerId, @RequestParam(required = false) String status, @RequestParam(required = false) Integer page, @RequestParam(required = false) Integer pageSize)

    @Operation(summary = "获取订单详情")
    public Result<VolunteerOrder> getOrderDetail(@PathVariable String id)

    @Operation(summary = "更新订单状态")
    public Result<Void> updateStatus(@PathVariable String id, @RequestBody Map<String, String> params)

    @Operation(summary = "完成订单")
    public Result<Void> complete(@PathVariable String id, @RequestBody Map<String, String> params)

    @Operation(summary = "获取订单进度")
    public Result<VolunteerOrder> getProgress(@PathVariable String id)
}
```

```java
// ChatMessageController.java
@Tag(name = "聊天")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class ChatMessageController {

    @Operation(summary = "发送聊天消息")
    public Result<ChatMessage> sendMessage(@RequestBody ChatMessage message, @RequestAttribute("userId") String senderId)

    @Operation(summary = "获取聊天历史")
    public Result<PageResult<ChatMessage>> getHistory(@PathVariable String requestId, @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "50") Integer pageSize)

    @Operation(summary = "批量标记消息已读")
    public Result<Void> markAsRead(@RequestBody Map<String, List<Long>> params)

    @Operation(summary = "获取未读消息数")
    public Result<Long> countUnread(@PathVariable String requestId, @RequestAttribute("userId") String userId)
}

// CommunityController.java
@Tag(name = "社区管理")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class CommunityController {

    @Operation(summary = "获取全部求助请求")
    public Result<PageResult<HelpRequest>> getAllRequests(@RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "10") Integer pageSize, @RequestParam(required = false) String status)

    @Operation(summary = "分配志愿者")
    public Result<VolunteerOrder> assignVolunteer(@RequestBody Map<String, String> params)

    @Operation(summary = "获取可用志愿者")
    public Result<List<CommunityVolunteerDto>> getAvailableVolunteers(@RequestParam(required = false) String requestId, @RequestParam(required = false) Double latitude, @RequestParam(required = false) Double longitude)

    @Operation(summary = "获取社区统计信息")
    public Result<Map<String, Object>> getStatistics()

    @Operation(summary = "获取志愿者管理视图")
    public Result<VolunteerManagementResponseDto> getVolunteerManagement(@RequestParam(required = false) String keyword)

    @Operation(summary = "获取快速派单推荐")
    public Result<QuickDispatchResponseDto> getDispatchRecommendations(@PathVariable String volunteerId)

    @Operation(summary = "审核求助请求")
    public Result<Void> reviewRequest(@PathVariable String id, @RequestBody Map<String, String> params)
}
```

```java
// UserController.java
@Tag(name = "用户")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class UserController {

    @Operation(summary = "获取指定用户信息")
    public Result<User> getUser(@PathVariable String id)

    @Operation(summary = "获取当前用户信息")
    public Result<User> getCurrentUser(@RequestAttribute("userId") String userId)

    @Operation(summary = "更新当前用户信息")
    public Result<User> updateUser(@RequestBody User user, @RequestAttribute("userId") String userId)

    @Operation(summary = "更新头像")
    public Result<Void> updateAvatar(@RequestBody Map<String, String> params, @RequestAttribute("userId") String userId)

    @Operation(summary = "设置角色")
    public Result<User> updateRole(@RequestBody Map<String, String> params, @RequestAttribute("userId") String userId)

    @Operation(summary = "切换角色")
    public Result<User> switchRole(@RequestBody Map<String, String> params, @RequestAttribute("userId") String userId)

    @Operation(summary = "上报当前位置")
    public Result<UserLocation> reportLocation(@RequestBody Map<String, Object> body, @RequestAttribute("userId") String userId)

    @Operation(summary = "获取我的位置")
    public Result<UserLocation> getMyLocation(@RequestAttribute("userId") String userId)

    @Operation(summary = "获取我的志愿技能")
    public Result<List<String>> getMyVolunteerSkills(@RequestAttribute("userId") String userId)

    @Operation(summary = "更新我的志愿技能")
    public Result<List<String>> updateMyVolunteerSkills(@RequestBody Map<String, Object> body, @RequestAttribute("userId") String userId)
}

// VolunteerController.java
@Tag(name = "志愿者概览")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class VolunteerController {

    @Operation(summary = "获取志愿者统计信息")
    public Result<VolunteerStatisticsDto> getStatistics(@RequestAttribute("userId") String userId)

    @Operation(summary = "获取附近求助列表")
    public Result<PageResult<HelpRequestWithDistanceDto>> getNearbyRequests(@RequestParam(required = false) Double latitude, @RequestParam(required = false) Double longitude, @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "10") Integer pageSize, @RequestAttribute("userId") String userId)
}
```

```java
// ReviewController.java
@Tag(name = "评价")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class ReviewController {

    @Operation(summary = "创建评价")
    public Result<Review> create(@RequestBody Review review, @RequestAttribute("userId") String reviewerId)

    @Operation(summary = "获取我发起的评价")
    public Result<Review> getMyReviewForOrder(@PathVariable String orderId, @RequestAttribute("userId") String userId)

    @Operation(summary = "获取我收到的评价")
    public Result<Review> getReviewReceived(@PathVariable String orderId, @RequestAttribute("userId") String userId)

    @Operation(summary = "回复评价")
    public Result<Void> reply(@PathVariable String id, @RequestBody Map<String, String> params)
}

// EmergencyController.java
@Tag(name = "紧急求助")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class EmergencyController {

    @Operation(summary = "创建紧急求助")
    public Result<HelpRequest> createEmergencyRequest(@RequestBody EmergencyRequestDto request, @RequestAttribute String userId, @RequestAttribute String userName, @RequestAttribute String userPhone)
}
```

- [ ] **Step 4: Re-run the test and confirm it passes**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help
mvn "-Dtest=OpenApiAnnotationsTest" test
```

Expected: `OpenApiAnnotationsTest` PASS.

- [ ] **Step 5: Commit**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help/src/main/java/com/csi/help/config/WebConfig.java help/src/main/java/com/csi/help/controller/AuthController.java help/src/main/java/com/csi/help/controller/GeocodeController.java help/src/main/java/com/csi/help/controller/HelpRequestController.java help/src/main/java/com/csi/help/controller/VolunteerOrderController.java help/src/main/java/com/csi/help/controller/ChatMessageController.java help/src/main/java/com/csi/help/controller/CommunityController.java help/src/main/java/com/csi/help/controller/UserController.java help/src/main/java/com/csi/help/controller/VolunteerController.java help/src/main/java/com/csi/help/controller/ReviewController.java help/src/main/java/com/csi/help/controller/EmergencyController.java help/src/test/java/com/csi/help/controller/OpenApiAnnotationsTest.java
git commit -m "docs: annotate controllers for OpenAPI export"
```

### Task 3: Add the Apifox onboarding guide

**Files:**
- Create: `help/APIFOX_AUTOMATION_GUIDE.md`

- [ ] **Step 1: Write the guide skeleton**

~~~markdown
# Apifox 自动化测试接入指南

> 以 `help` 后端导出的 `OpenAPI` 文档和真实 controller 路径为准，不再以旧版 markdown 接口清单作为导入基线。

## 1. OpenAPI 导入地址
- JSON: `http://localhost:8080/v3/api-docs`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`

## 2. 推荐分组
- 认证
- 求助请求
- 紧急求助
- 聊天
- 社区管理
- 用户
- 志愿者概览
- 志愿者订单
- 评价
- 地理编码
~~~

- [ ] **Step 2: Add env vars, collections, and script examples**

~~~markdown
## 3. 本地联调环境变量
- `baseUrl=http://localhost:8080`
- `seekerPhone`
- `seekerPassword`
- `volunteerPhone`
- `volunteerPassword`
- `communityPhone`
- `communityPassword`
- `seekerToken`
- `volunteerToken`
- `communityToken`
- `refreshToken`
- `requestId`
- `orderId`
- `chatRequestId`

## 4. 推荐自动化集合
- `Smoke-P0`
- `Auth`
- `Request`
- `Volunteer Flow`
- `Community`
- `Chat`

## 5. 后置脚本示例
```javascript
const body = pm.response.json();
pm.environment.set('seekerToken', body.data.token);
pm.environment.set('refreshToken', body.data.refreshToken);
```

```javascript
const body = pm.response.json();
pm.environment.set('requestId', body.data.id);
```

```javascript
const body = pm.response.json();
pm.environment.set('orderId', body.data.id);
```

## 6. 通用断言建议
```javascript
const body = pm.response.json();
pm.test('HTTP 200', () => pm.response.to.have.status(200));
pm.test('业务成功', () => pm.expect(body.code).to.eql(200));
pm.test('message success', () => pm.expect(body.message).to.eql('success'));
pm.test('timestamp exists', () => pm.expect(body.timestamp).to.be.ok);
```
~~~

- [ ] **Step 3: Run a static check for the key guide entries**

Run:

```powershell
Select-String -Path "C:\Users\22789\Desktop\endProject\help\APIFOX_AUTOMATION_GUIDE.md" -Pattern "/v3/api-docs|swagger-ui/index.html|seekerToken|Smoke-P0|requestId|orderId"
```

Expected: all key guide entries are matched.

- [ ] **Step 4: Verify the guide opens with the source-of-truth note**

Expected: the guide starts with this exact note.

```markdown
> 以 `help` 后端导出的 `OpenAPI` 文档和真实 controller 路径为准，不再以旧版 markdown 接口清单作为导入基线。
```

- [ ] **Step 5: Commit**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help/APIFOX_AUTOMATION_GUIDE.md
git commit -m "docs: add Apifox automation onboarding guide"
```

### Task 4: Verify the exported docs and Apifox import baseline locally

**Files:**
- Verify: `help/pom.xml`
- Verify: `help/src/main/java/com/csi/help/config/OpenApiConfig.java`
- Verify: `help/src/main/java/com/csi/help/config/WebConfig.java`
- Verify: `help/src/main/java/com/csi/help/controller/*.java`
- Verify: `help/src/test/java/com/csi/help/config/OpenApiConfigTest.java`
- Verify: `help/src/test/java/com/csi/help/controller/OpenApiAnnotationsTest.java`
- Verify: `help/APIFOX_AUTOMATION_GUIDE.md`

- [ ] **Step 1: Run the OpenAPI unit tests**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help
mvn "-Dtest=OpenApiConfigTest,OpenApiAnnotationsTest" test
```

Expected: `BUILD SUCCESS`.

- [ ] **Step 2: Start the backend and verify the JSON endpoint**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help
mvn spring-boot:run
```

In another PowerShell window run:

```powershell
(Invoke-WebRequest http://localhost:8080/v3/api-docs).StatusCode
```

Expected: `200`.

- [ ] **Step 3: Verify the Swagger UI page**

Run:

```powershell
(Invoke-WebRequest http://localhost:8080/swagger-ui/index.html).StatusCode
```

Expected: `200`.

- [ ] **Step 4: Spot-check exported routes and tags**

Run:

```powershell
$openApi = Invoke-RestMethod http://localhost:8080/v3/api-docs
$openApi.paths.PSObject.Properties.Name | Where-Object { $_ -in '/api/chat/{requestId}', '/api/volunteer/orders/accept', '/api/requests', '/api/auth/login' }
$openApi.tags.name
```

Expected:
- the route list includes `/api/chat/{requestId}`, `/api/volunteer/orders/accept`, `/api/requests`, `/api/auth/login`
- the tag list includes `认证`, `求助请求`, `志愿者订单`, `聊天`

- [ ] **Step 5: Commit**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help/pom.xml help/src/main/java/com/csi/help/config/OpenApiConfig.java help/src/main/java/com/csi/help/config/WebConfig.java help/src/main/java/com/csi/help/controller help/src/test/java/com/csi/help/config/OpenApiConfigTest.java help/src/test/java/com/csi/help/controller/OpenApiAnnotationsTest.java help/APIFOX_AUTOMATION_GUIDE.md
git commit -m "feat: expose OpenAPI docs for Apifox automation"
```

## Self-Review

- Spec coverage:
  - OpenAPI export: Task 1
  - Bearer security scheme: Task 1 and Task 2
  - Controller grouping and summaries: Task 2
  - Explicit doc-path allowlist: Task 2
  - Apifox import URL, env vars, scripts, and collections: Task 3
  - Local URL and export verification: Task 4

- Placeholder scan:
  - No `TODO`, `TBD`, or “implement later” placeholders remain.
  - Every task includes concrete files, code, commands, and expected results.

- Type consistency:
  - `OpenApiConfig.SECURITY_SCHEME_NAME` is consistently `bearerAuth`
  - protected controllers all reuse `@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)`
  - docs and automation examples consistently use `requestId`, `orderId`, `seekerToken`, `volunteerToken`, and `communityToken`
