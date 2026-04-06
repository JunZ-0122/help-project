package com.csi.help.service;

import cn.hutool.core.util.IdUtil;
import com.csi.help.entity.UserLocation;
import com.csi.help.mapper.UserLocationMapper;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class UserLocationService {

    private final UserLocationMapper userLocationMapper;

    public UserLocationService(UserLocationMapper userLocationMapper) {
        this.userLocationMapper = userLocationMapper;
    }

    /**
     * 上报或更新当前用户位置（UPSERT：有则更新，无则插入）
     */
    public UserLocation saveLocation(String userId, Double latitude, Double longitude, String address, String source) {
        if (latitude == null || longitude == null) {
            throw new IllegalArgumentException("经纬度不能为空");
        }
        UserLocation existing = userLocationMapper.findByUserId(userId);
        if (existing != null) {
            existing.setLatitude(latitude);
            existing.setLongitude(longitude);
            if (address != null) existing.setAddress(address);
            if (source != null) existing.setSource(source);
            userLocationMapper.update(existing);
            return existing;
        }
        UserLocation loc = new UserLocation();
        loc.setId(IdUtil.simpleUUID());
        loc.setUserId(userId);
        loc.setLatitude(latitude);
        loc.setLongitude(longitude);
        loc.setAddress(address);
        loc.setSource(source != null ? source : "app");
        userLocationMapper.insert(loc);
        return loc;
    }

    /**
     * 查询当前用户最近一次位置
     */
    public UserLocation getByUserId(String userId) {
        return userLocationMapper.findByUserId(userId);
    }
}
