package com.csi.help.dto;

import com.csi.help.entity.User;

/**
 * 登录响应
 */
public class LoginResponse {
    private String token;
    private String refreshToken;
    private Long expiresIn;
    private User user;

    public LoginResponse() {
    }

    public LoginResponse(String token, String refreshToken, Long expiresIn, User user) {
        this.token = token;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
        this.user = user;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public Long getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(Long expiresIn) {
        this.expiresIn = expiresIn;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }
}
