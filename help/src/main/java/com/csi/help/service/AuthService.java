package com.csi.help.service;

import cn.hutool.core.util.IdUtil;
import cn.hutool.crypto.SecureUtil;
import com.csi.help.dto.LoginRequest;
import com.csi.help.dto.LoginResponse;
import com.csi.help.dto.RegisterRequest;
import com.csi.help.entity.User;
import com.csi.help.mapper.UserMapper;
import com.csi.help.util.JwtUtil;
import org.springframework.stereotype.Service;

/**
 * 认证服务
 */
@Service
public class AuthService {
    
    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;

    public AuthService(UserMapper userMapper, JwtUtil jwtUtil) {
        this.userMapper = userMapper;
        this.jwtUtil = jwtUtil;
    }
    
    /**
     * 用户登录
     */
    public LoginResponse login(LoginRequest request) {
        // 查询用户
        User user = userMapper.findByPhone(request.getPhone());
        
        // 如果用户不存在，自动注册（验证码登录场景）
        if (user == null) {
            if ("sms".equals(request.getLoginType())) {
                // 验证码登录，自动创建用户
                user = new User();
                user.setId(IdUtil.simpleUUID());
                user.setName("用户" + request.getPhone().substring(7)); // 使用手机号后4位作为默认昵称
                user.setPhone(request.getPhone());
                user.setPassword(SecureUtil.md5(request.getPassword())); // 将验证码作为初始密码
                user.setRole(null); // 新用户角色为空，需要在角色选择页设置
                user.setStatus("online");
                
                userMapper.insert(user);
                System.out.println("自动注册新用户: " + user.getId());
            } else {
                throw new RuntimeException("用户不存在");
            }
        } else {
            // 验证密码
            String encryptedPassword = SecureUtil.md5(request.getPassword());
            if (!encryptedPassword.equals(user.getPassword())) {
                throw new RuntimeException("密码错误");
            }
        }
        
        // 生成 Token（role 可能为 null）
        String token = jwtUtil.generateToken(user.getId(), user.getRole());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());
        
        // 隐藏密码
        user.setPassword(null);
        
        return new LoginResponse(token, refreshToken, 7200L, user);
    }
    
    /**
     * 用户注册
     */
    public User register(RegisterRequest request) {
        // 检查手机号是否已注册
        User existUser = userMapper.findByPhone(request.getPhone());
        if (existUser != null) {
            throw new RuntimeException("手机号已注册");
        }
        
        // TODO: 验证验证码
        
        // 创建用户
        User user = new User();
        user.setId(IdUtil.simpleUUID());
        user.setName(request.getName());
        user.setPhone(request.getPhone());
        user.setPassword(SecureUtil.md5(request.getPassword()));
        user.setRole(request.getRole());
        user.setStatus("offline");
        
        userMapper.insert(user);
        
        // 隐藏密码
        user.setPassword(null);
        return user;
    }
    
    /**
     * 发送验证码
     */
    public void sendCode(String phone, String type) {
        // TODO: 实现发送短信验证码
        // 1. 生成 6 位验证码
        // 2. 存储到 Redis，有效期 5 分钟
        // 3. 调用短信服务发送
    }
    
    /**
     * 刷新 Token
     */
    public LoginResponse refreshToken(String refreshToken) {
        String userId = jwtUtil.validateRefreshToken(refreshToken);
        if (userId == null) {
            throw new RuntimeException("RefreshToken 无效");
        }
        
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        
        String newToken = jwtUtil.generateToken(user.getId(), user.getRole());
        String newRefreshToken = jwtUtil.generateRefreshToken(user.getId());
        
        user.setPassword(null);
        return new LoginResponse(newToken, newRefreshToken, 7200L, user);
    }
}
