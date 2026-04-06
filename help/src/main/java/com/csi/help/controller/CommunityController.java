package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.dto.CommunityVolunteerDto;
import com.csi.help.dto.QuickDispatchResponseDto;
import com.csi.help.dto.VolunteerManagementResponseDto;
import com.csi.help.entity.HelpRequest;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.service.CommunityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.List;

/**
 * 社区管理控制器
 */
@RestController
@RequestMapping("/api/community")
public class CommunityController {

    @Autowired
    private CommunityService communityService;

    /**
     * 获取所有求助请求（分页）
     */
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
    @GetMapping("/statistics")
    public Result<Map<String, Object>> getStatistics() {
        Map<String, Object> stats = communityService.getStatistics();
        return Result.success(stats);
    }

    /**
     * 志愿者管理页：汇总 KPI + 全量志愿者列表（可选关键词：姓名或技能）
     */
    @GetMapping("/volunteers/management")
    public Result<VolunteerManagementResponseDto> getVolunteerManagement(
            @RequestParam(required = false) String keyword) {
        return Result.success(communityService.getVolunteerManagementPage(keyword));
    }

    /**
     * 快速派单：对某志愿者的待派单求助打分并拆分智能推荐 / 其它待派单
     */
    @GetMapping("/volunteers/{volunteerId}/dispatch-recommendations")
    public Result<QuickDispatchResponseDto> getDispatchRecommendations(@PathVariable String volunteerId) {
        return Result.success(communityService.getQuickDispatchRecommendations(volunteerId));
    }

    /**
     * 审核求助请求
     */
    @PostMapping("/requests/{id}/review")
    public Result<Void> reviewRequest(@PathVariable String id,
                                        @RequestBody Map<String, String> params) {
        String status = params.get("status");
        communityService.reviewRequest(id, status);
        return Result.success();
    }
}
