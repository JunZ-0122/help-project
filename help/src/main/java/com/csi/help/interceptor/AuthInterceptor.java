package com.csi.help.interceptor;

import com.csi.help.entity.User;
import com.csi.help.mapper.UserMapper;
import com.csi.help.util.JwtUtil;
import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 认证拦截器
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {
    
    private final JwtUtil jwtUtil;
    private final UserMapper userMapper;

    public AuthInterceptor(JwtUtil jwtUtil, UserMapper userMapper) {
        this.jwtUtil = jwtUtil;
        this.userMapper = userMapper;
    }
    
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // 跨域预检请求直接放行
        if ("OPTIONS".equals(request.getMethod())) {
            return true;
        }
        
        // 获取 Token
        String token = request.getHeader("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            response.setStatus(401);
            return false;
        }
        
        token = token.substring(7);
        
        // 验证 Token
        Claims claims = jwtUtil.validateToken(token);
        if (claims == null) {
            response.setStatus(401);
            return false;
        }
        
        // 获取用户信息
        String userId = claims.getSubject();
        User user = userMapper.findById(userId);
        if (user == null) {
            response.setStatus(401);
            return false;
        }
        
        // 将用户信息存入请求属性
        request.setAttribute("userId", user.getId());
        request.setAttribute("userName", user.getName());
        request.setAttribute("userPhone", user.getPhone());
        request.setAttribute("userRole", user.getRole());
        
        return true;
    }
}
