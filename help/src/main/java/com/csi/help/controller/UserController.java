package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.entity.User;
import com.csi.help.entity.UserLocation;
import com.csi.help.service.UserLocationService;
import com.csi.help.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private static final Logger log = LoggerFactory.getLogger(UserController.class);

    @Autowired
    private UserService userService;

    @Autowired
    private UserLocationService userLocationService;

    @GetMapping("/{id}")
    public Result<User> getUser(@PathVariable String id) {
        User user = userService.getById(id);
        if (user == null) {
            return Result.error("\u7528\u6237\u4e0d\u5b58\u5728");
        }
        user.setPassword(null);
        return Result.success(user);
    }

    @GetMapping("/me")
    public Result<User> getCurrentUser(@RequestAttribute("userId") String userId) {
        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("\u7528\u6237\u4e0d\u5b58\u5728");
        }
        user.setPassword(null);
        return Result.success(user);
    }

    @PutMapping("/me")
    public Result<User> updateUser(@RequestBody User user,
                                   @RequestAttribute("userId") String userId) {
        user.setId(userId);
        user.setPassword(null);
        user.setRole(null);
        userService.update(user);

        User updatedUser = userService.getById(userId);
        if (updatedUser == null) {
            return Result.error("\u7528\u6237\u4e0d\u5b58\u5728");
        }

        updatedUser.setPassword(null);
        return Result.success(updatedUser);
    }

    @PutMapping("/me/avatar")
    public Result<Void> updateAvatar(@RequestBody Map<String, String> params,
                                     @RequestAttribute("userId") String userId) {
        String avatarUrl = params.get("avatarUrl");
        userService.updateAvatar(userId, avatarUrl);
        return Result.success();
    }

    @PutMapping("/me/role")
    public Result<User> updateRole(@RequestBody Map<String, String> params,
                                   @RequestAttribute("userId") String userId) {
        String role = params.get("role");

        if (role == null || (!role.equals("help-seeker") && !role.equals("volunteer") && !role.equals("community"))) {
            return Result.error("\u65e0\u6548\u7684\u89d2\u8272\u7c7b\u578b");
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("\u7528\u6237\u4e0d\u5b58\u5728");
        }

        if (user.getRole() != null && !user.getRole().isEmpty()) {
            return Result.error("\u7528\u6237\u5df2\u6709\u89d2\u8272\uff0c\u4e0d\u5141\u8bb8\u4fee\u6539");
        }

        userService.updateRole(userId, role);

        user = userService.getById(userId);
        user.setPassword(null);
        return Result.success(user);
    }

    @PutMapping("/me/role/switch")
    public Result<User> switchRole(@RequestBody Map<String, String> params,
                                   @RequestAttribute("userId") String userId) {
        String newRole = params.get("role");

        if (newRole == null || (!newRole.equals("help-seeker") && !newRole.equals("volunteer") && !newRole.equals("community"))) {
            return Result.error("\u65e0\u6548\u7684\u89d2\u8272\u7c7b\u578b");
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("\u7528\u6237\u4e0d\u5b58\u5728");
        }

        if (newRole.equals(user.getRole())) {
            return Result.error("\u5f53\u524d\u5df2\u662f\u8be5\u89d2\u8272\uff0c\u65e0\u9700\u5207\u6362");
        }

        userService.updateRole(userId, newRole);

        user = userService.getById(userId);
        user.setPassword(null);
        return Result.success(user);
    }

    /**
     * 上报当前用户位置（经纬度必填，address、source 可选）
     */
    @PostMapping("/me/location")
    public Result<UserLocation> reportLocation(@RequestBody Map<String, Object> body,
                                               @RequestAttribute("userId") String userId) {
        log.info("[User] 上报位置: userId={}", userId);
        Object lat = body.get("latitude");
        Object lng = body.get("longitude");
        if (lat == null || lng == null) {
            log.warn("[User] 上报位置失败: 经纬度为空");
            return Result.error("经纬度不能为空");
        }
        double latitude = ((Number) lat).doubleValue();
        double longitude = ((Number) lng).doubleValue();
        String address = body.get("address") != null ? body.get("address").toString() : null;
        String source = body.get("source") != null ? body.get("source").toString() : null;
        UserLocation loc = userLocationService.saveLocation(userId, latitude, longitude, address, source);
        log.info("[User] 上报位置成功: userId={}, lat={}, lng={}", userId, latitude, longitude);
        return Result.success(loc);
    }

    /**
     * 查询当前用户最近一次位置
     */
    @GetMapping("/me/location")
    public Result<UserLocation> getMyLocation(@RequestAttribute("userId") String userId) {
        log.info("[User] 查询我的位置: userId={}", userId);
        UserLocation loc = userLocationService.getByUserId(userId);
        if (loc == null) {
            log.info("[User] 暂无位置: userId={}", userId);
            return Result.error("暂无位置信息");
        }
        return Result.success(loc);
    }
}
