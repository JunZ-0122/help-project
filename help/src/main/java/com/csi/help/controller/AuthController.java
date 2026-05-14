package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.config.OpenApiConfig;
import com.csi.help.dto.LoginRequest;
import com.csi.help.dto.LoginResponse;
import com.csi.help.dto.RegisterRequest;
import com.csi.help.dto.SendCodeResponse;
import com.csi.help.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin
@Tag(name = "认证")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @Operation(summary = "用户登录")
    @PostMapping("/login")
    public Result<LoginResponse> login(@Validated @RequestBody LoginRequest request) {
        log.info("[Auth] login request: phone={}", request != null ? request.getPhone() : "");
        try {
            LoginResponse response = authService.login(request);
            log.info("[Auth] login success: userId={}",
                    response != null && response.getUser() != null ? response.getUser().getId() : "");
            return Result.success(response);
        } catch (Exception e) {
            log.warn("[Auth] login failed: {}", e.getMessage());
            return Result.error(e.getMessage());
        }
    }

    @Operation(summary = "用户注册")
    @PostMapping("/register")
    public Result<LoginResponse> register(@Validated @RequestBody RegisterRequest request) {
        try {
            LoginResponse response = authService.register(request);
            return Result.success(response);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }

    @Operation(summary = "发送验证码")
    @PostMapping("/send-code")
    public Result<SendCodeResponse> sendCode(@RequestBody Map<String, String> request) {
        try {
            String phone = request.get("phone");
            String type = request.get("type");
            SendCodeResponse response = authService.sendCode(phone, type);
            return Result.success(response);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }

    @Operation(summary = "刷新访问令牌")
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

    @Operation(summary = "退出登录")
    @SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
    @PostMapping("/logout")
    public Result<Void> logout() {
        return Result.success();
    }
}
