package com.csi.help.service;

import com.csi.help.entity.User;
import com.csi.help.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 用户服务
 */
@Service
public class UserService {

    @Autowired
    private UserMapper userMapper;

    /**
     * 根据 ID 获取用户
     */
    public User getById(String id) {
        return userMapper.findById(id);
    }

    /**
     * 更新用户信息
     */
    @Transactional
    public void update(User user) {
        userMapper.update(user);
    }

    /**
     * 更新用户头像
     */
    @Transactional
    public void updateAvatar(String userId, String avatarUrl) {
        User user = new User();
        user.setId(userId);
        user.setAvatar(avatarUrl);
        userMapper.update(user);
    }

    /**
     * 更新用户角色
     */
    @Transactional
    public void updateRole(String userId, String role) {
        User user = new User();
        user.setId(userId);
        user.setRole(role);
        userMapper.update(user);
    }
}
