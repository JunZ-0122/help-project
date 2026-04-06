package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.dto.EmergencyRequestDto;
import com.csi.help.entity.HelpRequest;
import com.csi.help.service.HelpRequestService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

/**
 * 紧急求助：发布入口 {@code POST /api/emergency/requests}（需登录 Bearer Token）。
 * 请求体：type(medical|safety|accident|other)、description、location、contactPhone，可选 latitude/longitude。
 */
@RestController
@RequestMapping("/api/emergency")
@CrossOrigin
public class EmergencyController {

    private static final Logger log = LoggerFactory.getLogger(EmergencyController.class);
    private final HelpRequestService helpRequestService;

    public EmergencyController(HelpRequestService helpRequestService) {
        this.helpRequestService = helpRequestService;
    }

    @PostMapping("/requests")
    public Result<HelpRequest> createEmergencyRequest(@RequestBody EmergencyRequestDto request,
                                                      @RequestAttribute String userId,
                                                      @RequestAttribute String userName,
                                                      @RequestAttribute String userPhone) {
        log.info("[Emergency] 创建紧急求助: userId={}, type={}, location={}", userId, request.getType(), request.getLocation());
        if (isBlank(request.getType())) {
            return Result.error("\u7d27\u6025\u7c7b\u578b\u4e0d\u80fd\u4e3a\u7a7a");
        }
        if (!isSupportedType(request.getType())) {
            return Result.error("\u4e0d\u652f\u6301\u7684\u7d27\u6025\u7c7b\u578b");
        }
        if (isBlank(request.getDescription())) {
            return Result.error("\u7d27\u6025\u60c5\u51b5\u8bf4\u660e\u4e0d\u80fd\u4e3a\u7a7a");
        }
        if (isBlank(request.getLocation())) {
            return Result.error("\u4f4d\u7f6e\u4fe1\u606f\u4e0d\u80fd\u4e3a\u7a7a");
        }
        if (isBlank(request.getContactPhone())) {
            return Result.error("\u8054\u7cfb\u7535\u8bdd\u4e0d\u80fd\u4e3a\u7a7a");
        }

        try {
            HelpRequest createdRequest = helpRequestService.createEmergencyRequest(
                    request,
                    userId,
                    userName,
                    userPhone
            );
            log.info("[Emergency] 紧急求助创建成功: requestId={}", createdRequest.getId());
            return Result.success(createdRequest);
        } catch (Exception e) {
            log.warn("[Emergency] 创建失败: {}", e.getMessage());
            return Result.error(e.getMessage());
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isSupportedType(String type) {
        return "medical".equals(type)
                || "safety".equals(type)
                || "accident".equals(type)
                || "other".equals(type);
    }
}
