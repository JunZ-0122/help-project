package com.csi.help.service;

import cn.hutool.core.util.IdUtil;
import com.csi.help.dto.LoginRequest;
import com.csi.help.dto.LoginResponse;
import com.csi.help.dto.RegisterRequest;
import com.csi.help.dto.SendCodeResponse;
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
    private final VerificationCodeService verificationCodeService;
    private final AuthPasswordService authPasswordService;

    public AuthService(UserMapper userMapper,
                       JwtUtil jwtUtil,
                       VerificationCodeService verificationCodeService,
                       AuthPasswordService authPasswordService) {
        this.userMapper = userMapper;
        this.jwtUtil = jwtUtil;
        this.verificationCodeService = verificationCodeService;
        this.authPasswordService = authPasswordService;
    }

    public LoginResponse login(LoginRequest request) {
        String loginType = request.getLoginType() == null || request.getLoginType().isBlank()
                ? "password"
                : request.getLoginType();

        User user = userMapper.findByPhone(request.getPhone());

        if ("sms".equals(loginType)) {
            String verificationCode = request.getVerificationCode();
            if (verificationCode == null || verificationCode.isBlank()) {
                throw new RuntimeException("验证码不能为空");
            }
            verificationCodeService.verifyCode(request.getPhone(), "login", verificationCode);

            if (user == null) {
                user = new User();
                user.setId(IdUtil.simpleUUID());
                user.setName("用户" + request.getPhone().substring(7));
                user.setPhone(request.getPhone());
                AuthPasswordService.PasswordSnapshot snapshot = authPasswordService.createSaltedPassword("123456");
                user.setPassword(snapshot.passwordHash());
                user.setSalt(snapshot.salt());
                user.setRole(null);
                user.setStatus("online");
                userMapper.insert(user);
            }
        } else if ("password".equals(loginType)) {
            String password = request.getPassword();
            if (password == null || password.isBlank()) {
                throw new RuntimeException("密码不能为空");
            }
            if (user == null) {
                throw new RuntimeException("用户不存在");
            }

            boolean matched;
            if (user.getSalt() != null && !user.getSalt().isBlank()) {
                matched = authPasswordService.matches(password, user.getPassword(), user.getSalt());
            } else {
                matched = authPasswordService.matchesLegacyMd5(password, user.getPassword());
                if (matched) {
                    AuthPasswordService.PasswordSnapshot snapshot = authPasswordService.createSaltedPassword(password);
                    userMapper.updatePasswordAndSalt(user.getId(), snapshot.passwordHash(), snapshot.salt());
                    user.setPassword(snapshot.passwordHash());
                    user.setSalt(snapshot.salt());
                }
            }
            if (!matched) {
                throw new RuntimeException("密码错误");
            }
        } else {
            throw new RuntimeException("不支持的登录类型");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getRole());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());
        return new LoginResponse(token, refreshToken, 7200L, sanitizeUser(user));
    }

    public LoginResponse register(RegisterRequest request) {
        User existUser = userMapper.findByPhone(request.getPhone());
        if (existUser != null) {
            throw new RuntimeException("手机号已注册");
        }

        verificationCodeService.verifyCode(request.getPhone(), "register", request.getVerificationCode());

        User user = new User();
        user.setId(IdUtil.simpleUUID());
        user.setName(request.getName());
        user.setPhone(request.getPhone());
        AuthPasswordService.PasswordSnapshot snapshot = authPasswordService.createSaltedPassword("123456");
        user.setPassword(snapshot.passwordHash());
        user.setSalt(snapshot.salt());
        user.setRole(request.getRole());
        user.setStatus("offline");
        userMapper.insert(user);

        String token = jwtUtil.generateToken(user.getId(), user.getRole());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());
        return new LoginResponse(token, refreshToken, 7200L, sanitizeUser(user));
    }

    public SendCodeResponse sendCode(String phone, String type) {
        return verificationCodeService.sendCode(phone, type);
    }

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
        return new LoginResponse(newToken, newRefreshToken, 7200L, sanitizeUser(user));
    }

    private User sanitizeUser(User user) {
        User safeUser = new User();
        safeUser.setId(user.getId());
        safeUser.setName(user.getName());
        safeUser.setPhone(user.getPhone());
        safeUser.setAvatar(user.getAvatar());
        safeUser.setRole(user.getRole());
        safeUser.setStatus(user.getStatus());
        safeUser.setCreatedAt(user.getCreatedAt());
        safeUser.setUpdatedAt(user.getUpdatedAt());
        safeUser.setAge(user.getAge());
        safeUser.setGender(user.getGender());
        safeUser.setAddress(user.getAddress());
        safeUser.setEmergencyContact(user.getEmergencyContact());
        safeUser.setEmergencyPhone(user.getEmergencyPhone());
        safeUser.setDisabilities(user.getDisabilities());
        safeUser.setCertifications(user.getCertifications());
        safeUser.setVolunteerHours(user.getVolunteerHours());
        safeUser.setRating(user.getRating());
        return safeUser;
    }
}
