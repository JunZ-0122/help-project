package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.entity.User;
import com.csi.help.entity.UserLocation;
import com.csi.help.service.UserLocationService;
import com.csi.help.service.UserService;
import com.csi.help.service.VolunteerSkillService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private static final Logger log = LoggerFactory.getLogger(UserController.class);

    @Autowired
    private UserService userService;

    @Autowired
    private UserLocationService userLocationService;

    @Autowired
    private VolunteerSkillService volunteerSkillService;

    @GetMapping("/{id}")
    public Result<User> getUser(@PathVariable String id) {
        User user = userService.getById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }
        user.setPassword(null);
        return Result.success(user);
    }

    @GetMapping("/me")
    public Result<User> getCurrentUser(@RequestAttribute("userId") String userId) {
        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("用户不存在");
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
            return Result.error("用户不存在");
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
            return Result.error("无效的角色类型");
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }

        if (user.getRole() != null && !user.getRole().isEmpty() && !"default".equals(user.getRole())) {
            return Result.error("用户已有角色，不允许修改");
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
            return Result.error("无效的角色类型");
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }

        if (newRole.equals(user.getRole())) {
            return Result.error("当前已是该角色，无需切换");
        }

        userService.updateRole(userId, newRole);

        user = userService.getById(userId);
        user.setPassword(null);
        return Result.success(user);
    }

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

    @GetMapping("/me/volunteer-skills")
    public Result<List<String>> getMyVolunteerSkills(@RequestAttribute("userId") String userId) {
        return Result.success(volunteerSkillService.getSkills(userId));
    }

    @PutMapping("/me/volunteer-skills")
    public Result<List<String>> updateMyVolunteerSkills(@RequestBody Map<String, Object> body,
                                                        @RequestAttribute("userId") String userId) {
        Object rawSkills = body.get("skills");
        List<String> skillCodes = new ArrayList<>();
        if (rawSkills instanceof List<?>) {
            for (Object item : (List<?>) rawSkills) {
                if (item != null) {
                    skillCodes.add(item.toString());
                }
            }
        }
        try {
            return Result.success(volunteerSkillService.replaceSkills(userId, skillCodes));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
