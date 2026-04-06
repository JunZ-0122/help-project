package com.csi.help.mapper;

import com.csi.help.entity.UserLocation;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface UserLocationMapper {

    int insert(UserLocation location);

    int update(UserLocation location);

    UserLocation findByUserId(@Param("userId") String userId);
}
