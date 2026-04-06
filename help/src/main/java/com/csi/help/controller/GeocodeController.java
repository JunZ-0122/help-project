package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.service.AmapService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 地理编码/逆地理编码（供前端根据经纬度获取地址描述）
 */
@RestController
@RequestMapping("/api/geocode")
@CrossOrigin
public class GeocodeController {

    private static final Logger log = LoggerFactory.getLogger(GeocodeController.class);
    private final AmapService amapService;

    public GeocodeController(AmapService amapService) {
        this.amapService = amapService;
    }

    /**
     * 逆地理：经纬度 → 格式化地址（用于「获取当前位置」自动填充）
     */
    @GetMapping("/regeo")
    public Result<Map<String, String>> regeo(
            @RequestParam double latitude,
            @RequestParam double longitude) {
        log.info("[Geocode] regeo 请求: latitude={}, longitude={}", latitude, longitude);
        String address = amapService.regeo(longitude, latitude);
        log.info("[Geocode] regeo 结果: address={}", address != null ? address : "(空)");
        Map<String, String> data = new HashMap<>();
        data.put("address", address != null ? address : "");
        return Result.success(data);
    }
}
