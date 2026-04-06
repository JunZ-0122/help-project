package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.entity.HelpRequest;
import com.csi.help.service.HelpRequestService;
import com.csi.help.vo.SeekerRequestDetailVo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 求助请求控制器
 */
@RestController
@RequestMapping("/api/requests")
@CrossOrigin
public class HelpRequestController {

    private static final Logger log = LoggerFactory.getLogger(HelpRequestController.class);

    private final HelpRequestService helpRequestService;

    public HelpRequestController(HelpRequestService helpRequestService) {
        this.helpRequestService = helpRequestService;
    }
    
    /**
     * 获取求助列表
     */
    @GetMapping
    public Result<PageResult<HelpRequest>> getRequests(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String urgency,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        log.info("[Requests] 获取列表: type={}, status={}, page={}, pageSize={}", type, status, page, pageSize);
        try {
            PageResult<HelpRequest> result = helpRequestService.getRequests(type, status, urgency, page, pageSize);
            log.info("[Requests] 列表结果: total={}", result != null ? result.getTotal() : 0);
            return Result.success(result);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 创建求助
     */
    @PostMapping
    public Result<HelpRequest> create(@RequestBody HelpRequest request,
                                       @RequestAttribute String userId,
                                       @RequestAttribute String userName,
                                       @RequestAttribute String userPhone) {
        log.info("[Requests] 创建求助: userId={}, type={}, location={}", userId, request != null ? request.getType() : "", request != null ? request.getLocation() : "");
        try {
            HelpRequest created = helpRequestService.create(request, userId, userName, userPhone);
            log.info("[Requests] 创建成功: requestId={}", created != null ? created.getId() : "");
            return Result.success(created);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 求助者本人：详情页聚合（时间线、横幅、志愿者信息等）
     */
    @GetMapping("/{id}/seeker-detail")
    public Result<SeekerRequestDetailVo> getSeekerDetail(@PathVariable String id,
                                                         @RequestAttribute String userId) {
        try {
            return Result.success(helpRequestService.getSeekerRequestDetail(id, userId));
        } catch (Exception e) {
            String msg = e.getMessage();
            if (msg != null && msg.contains("\u65e0\u6743")) {
                return Result.error(403, msg);
            }
            if (msg != null && msg.contains("\u4e0d\u5b58\u5728")) {
                return Result.error(404, msg);
            }
            return Result.error(msg != null ? msg : "error");
        }
    }

    /**
     * 获取求助详情
     */
    @GetMapping("/{id}")
    public Result<HelpRequest> getById(@PathVariable String id) {
        try {
            HelpRequest request = helpRequestService.getById(id);
            return Result.success(request);
        } catch (Exception e) {
            return Result.error(404, e.getMessage());
        }
    }
    
    /**
     * 更新求助
     */
    @PutMapping("/{id}")
    public Result<HelpRequest> update(@PathVariable String id, @RequestBody HelpRequest request) {
        try {
            HelpRequest updated = helpRequestService.update(id, request);
            return Result.success(updated);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 取消求助
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable String id) {
        try {
            helpRequestService.cancel(id);
            return Result.success();
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
    
    /**
     * 获取我的求助列表
     */
    @GetMapping("/my")
    public Result<PageResult<HelpRequest>> getMyRequests(
            @RequestAttribute String userId,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        try {
            PageResult<HelpRequest> result = helpRequestService.getMyRequests(userId, page, pageSize);
            return Result.success(result);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }

    /**
     * 首页最近求助（按更新时间，默认 3 条）
     */
    @GetMapping("/my/recent")
    public Result<List<HelpRequest>> getRecentMyRequests(
            @RequestAttribute String userId,
            @RequestParam(defaultValue = "3") Integer limit) {
        try {
            List<HelpRequest> list = helpRequestService.getRecentMyRequests(userId, limit);
            return Result.success(list);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
}
