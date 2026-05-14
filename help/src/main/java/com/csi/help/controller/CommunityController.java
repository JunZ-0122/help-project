package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.config.OpenApiConfig;
import com.csi.help.dto.CommunityVolunteerDto;
import com.csi.help.dto.QuickDispatchResponseDto;
import com.csi.help.dto.VolunteerManagementResponseDto;
import com.csi.help.entity.HelpRequest;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.service.CommunityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.List;

/**
 * 社区管理控制器
 */
@RestController
@RequestMapping("/api/community")
@Tag(name = "社区管理")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class CommunityController {

    @Autowired
    private CommunityService communityService;

    /**
     * 获取所有求助请求（分页）
     */
    @Operation(summary = "获取全部求助请求")
    @GetMapping("/requests")
    public Result<PageResult<HelpRequest>> getAllRequests(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String status) {
        PageResult<HelpRequest> result = communityService.getAllRequests(page, pageSize, status);
        return Result.success(result);
    }

    /**
     * 分配志愿者
     */
    @Operation(summary = "分配志愿者")
    @PostMapping("/assign")
    public Result<VolunteerOrder> assignVolunteer(@RequestBody Map<String, String> params) {
        String requestId = params.get("requestId");
        String volunteerId = params.get("volunteerId");
        VolunteerOrder order = communityService.assignVolunteer(requestId, volunteerId);
        return Result.success(order);
    }

    /**
     * 获取可用志愿者；可选 requestId 或 latitude+longitude，用于按距离排序
     */
    @Operation(summary = "获取可用志愿者")
    @GetMapping("/volunteers/available")
    public Result<List<CommunityVolunteerDto>> getAvailableVolunteers(
            @RequestParam(required = false) String requestId,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude) {
        List<CommunityVolunteerDto> volunteers =
                communityService.getAvailableVolunteers(requestId, latitude, longitude);
        return Result.success(volunteers);
    }

    /**
     * 获取统计数据
     */
    @Operation(summary = "获取社区统计信息")
    @GetMapping("/statistics")
    public Result<Map<String, Object>> getStatistics() {
        Map<String, Object> stats = communityService.getStatistics();
        return Result.success(stats);
    }

    /**
     * 志愿者管理页：汇总 KPI + 全量志愿者列表（可选关键词：姓名或技能）
     */
    @Operation(summary = "获取志愿者管理视图")
    @GetMapping("/volunteers/management")
    public Result<VolunteerManagementResponseDto> getVolunteerManagement(
            @RequestParam(required = false) String keyword) {
        return Result.success(communityService.getVolunteerManagementPage(keyword));
    }

    /**
     * 快速派单：对某志愿者的待派单求助打分并拆分智能推荐 / 其它待派单
     */
    @Operation(summary = "获取快速派单推荐")
    @GetMapping("/volunteers/{volunteerId}/dispatch-recommendations")
    public Result<QuickDispatchResponseDto> getDispatchRecommendations(@PathVariable String volunteerId) {
        return Result.success(communityService.getQuickDispatchRecommendations(volunteerId));
    }

    /**
     * 审核求助请求
     */
    @Operation(summary = "审核求助请求")
    @PostMapping("/requests/{id}/review")
    public Result<Void> reviewRequest(@PathVariable String id,
                                        @RequestBody Map<String, String> params) {
        String status = params.get("status");
        communityService.reviewRequest(id, status);
        return Result.success();
    }
}
