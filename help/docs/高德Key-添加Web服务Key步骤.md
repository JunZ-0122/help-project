# 高德 Key：添加「Web 服务」Key 步骤

当前 Key 绑定的是 **Web端**（浏览器用），后端调用逆地理/地理编码必须用 **Web服务** Key，否则会报 `USERKEY_PLAT_NOMATCH`。

## 操作步骤（在高德控制台完成）

1. 打开 [高德开放平台控制台](https://console.amap.com/) → **应用管理** → 选中应用 **help**。

2. 点击 **「添加Key」**（和「编辑」「删除」同一行右侧）。

3. 填写：
   - **Key 名称**：随意，例如 `help-server` 或 `后端Web服务`。
   - **服务平台** / **绑定服务**：**必须选「Web服务」**（不要选 Web端、iOS、Android、JS 等）。
   - 若有「IP 白名单」等可选项，开发阶段可先不填。

4. 提交后，在 Key 列表里会多出一行，**绑定服务** 为 **Web服务**，复制该 Key 的值。

5. 在项目里配置该 Key：
   - 打开 `help/src/main/resources/application.yml`。
   - 找到 `amap.web-service-key`，把 `979048b553c25febcd9efb0549d9526c` 换成刚复制的 **Web服务** Key（或设置环境变量 `AMAP_WEB_SERVICE_KEY`）。

6. 重启后端，再访问演示页或应用内「获取位置」测试逆地理。

## 区分

| 绑定服务 | 用途           | 后端 regeo/geocode |
|----------|----------------|---------------------|
| Web端    | 浏览器、H5 页面 | ❌ 会报 USERKEY_PLAT_NOMATCH |
| **Web服务** | 服务器 HTTP 请求 | ✅ 使用此项 |
