package com.csi.help.mapper;

import com.csi.help.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

/**
 * 用户 Mapper
 */
@Mapper
public interface UserMapper {
    
    /**
     * 根据手机号查询用户
     */
    User findByPhone(@Param("phone") String phone);
    
    /**
     * 根据 ID 查询用户
     */
    User findById(@Param("id") String id);

    List<User> findByRole(@Param("role") String role);
    
    /**
     * 插入用户
     */
    int insert(User user);
    
    /**
     * 更新用户信息
     */
    int update(User user);
    
    /**
     * 更新用户状态
     */
    int updateStatus(@Param("id") String id, @Param("status") String status);
}
