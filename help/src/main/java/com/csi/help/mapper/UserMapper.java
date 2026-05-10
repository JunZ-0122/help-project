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

    User findByPhone(@Param("phone") String phone);

    User findById(@Param("id") String id);

    List<User> findByRole(@Param("role") String role);

    int insert(User user);

    int update(User user);

    int updatePasswordAndSalt(@Param("id") String id,
                              @Param("password") String password,
                              @Param("salt") String salt);

    int updateStatus(@Param("id") String id, @Param("status") String status);
}
