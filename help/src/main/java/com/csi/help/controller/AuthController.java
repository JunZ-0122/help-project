package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.dto.LoginRequest;
import com.csi.help.dto.LoginResponse;
import com.csi.help.dto.RegisterRequest;
import com.csi.help.entity.User;
import com.csi.help.service.AuthService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }
    
    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<LoginResponse> login(@Validated @RequestBody LoginRequest request) {
        log.info("[Auth] 登录请求: phone={}", request != null ? request.getPhone() : "");
        try {
            LoginResponse response = authService.login(request);
            log.info("[Auth] 登录成功: userId={}", response != null && response.getUser() != null ? response.getUser().getId() : "");
            return Result.success(response);
        } catch (Exception e) {
            log.warn("[Auth] 登录失败: {}", e.getMessage());
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 用户注册
     */
    @PostMapping("/register")
    public Result<User> register(@Validated @RequestBody RegisterRequest request) {
        try {
            User user = authService.register(request);
            return Result.success(user);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 发送验证码
     */
    @PostMapping("/send-code")
    public Result<Void> sendCode(@RequestBody Map<String, String> request) {
        try {
            String phone = request.get("phone");
            String type = request.get("type");
            authService.sendCode(phone, type);
            return Result.success();
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 刷新 Token
     */
    @PostMapping("/refresh-token")
    public Result<LoginResponse> refreshToken(@RequestBody Map<String, String> request) {
        try {
            String refreshToken = request.get("refreshToken");
            LoginResponse response = authService.refreshToken(refreshToken);
            return Result.success(response);
        } catch (Exception e) {
            return Result.error(401, e.getMessage());
        }
    }
    
    /**
     * 退出登录
     */
    @PostMapping("/logout")
    public Result<Void> logout() {
        // TODO: 将 Token 加入黑名单
        return Result.success();
    }
}
