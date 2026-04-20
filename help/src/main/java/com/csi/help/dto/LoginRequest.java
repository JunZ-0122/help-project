package com.csi.help.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 登录请求（兼容密码登录与短信登录）
 */
public class LoginRequest {
    @NotBlank(message = "手机号不能为空")
    private String phone;

    /** 密码登录使用 */
    private String password;

    /** 短信登录使用 */
    private String verificationCode;

    /** password | sms，默认 password */
    private String loginType;

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getVerificationCode() {
        return verificationCode;
    }

    public void setVerificationCode(String verificationCode) {
        this.verificationCode = verificationCode;
    }

    public String getLoginType() {
        return loginType;
    }

    public void setLoginType(String loginType) {
        this.loginType = loginType;
    }
}
