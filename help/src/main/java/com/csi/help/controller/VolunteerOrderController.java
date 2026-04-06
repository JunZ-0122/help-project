package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.service.VolunteerOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 志愿者订单控制器
 */
@RestController
@RequestMapping("/api/volunteer/orders")
public class VolunteerOrderController {

    @Autowired
    private VolunteerOrderService volunteerOrderService;

    /**
     * 接受求助请求
     */
    @PostMapping("/accept")
    public Result<VolunteerOrder> acceptOrder(@RequestBody Map<String, String> params,
                                                @RequestAttribute("userId") String volunteerId) {
        String requestId = params.get("requestId");
        VolunteerOrder order = volunteerOrderService.acceptOrder(requestId, volunteerId);
        return Result.success(order);
    }

    /**
     * \u83b7\u53d6\u6211\u7684\u8ba2\u5355\u5217\u8868\u3002\u4f20 page\u3001pageSize \u65f6\u8fd4\u56de\u5206\u9875\u7ed3\u6784\u4e0e\u524d\u7aef PageResponse \u4e00\u81f4
     */
    @GetMapping("/my")
    public Result<?> getMyOrders(@RequestAttribute("userId") String volunteerId,
                                   @RequestParam(required = false) String status,
                                   @RequestParam(required = false) Integer page,
                                   @RequestParam(required = false) Integer pageSize) {
        if (page != null && pageSize != null && page > 0 && pageSize > 0) {
            PageResult<VolunteerOrder> pageResult =
                    volunteerOrderService.getMyOrdersPage(volunteerId, status, page, pageSize);
            return Result.success(pageResult);
        }
        List<VolunteerOrder> orders = volunteerOrderService.getMyOrders(volunteerId, status);
        return Result.success(orders);
    }

    /**
     * 获取订单详情
     */
    @GetMapping("/{id}")
    public Result<VolunteerOrder> getOrderDetail(@PathVariable String id) {
        VolunteerOrder order = volunteerOrderService.getById(id);
        if (order == null) {
            return Result.error("订单不存在");
        }
        return Result.success(order);
    }

    /**
     * 更新订单状态
     */
    @PutMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable String id,
                                       @RequestBody Map<String, String> params) {
        String status = params.get("status");
        volunteerOrderService.updateStatus(id, status);
        return Result.success();
    }

    /**
     * 完成订单
     */
    @PostMapping("/{id}/complete")
    public Result<Void> complete(@PathVariable String id,
                                   @RequestBody Map<String, String> params) {
        String feedback = params.get("feedback");
        volunteerOrderService.complete(id, feedback);
        return Result.success();
    }

    /**
     * 获取订单进度
     */
    @GetMapping("/{id}/progress")
    public Result<VolunteerOrder> getProgress(@PathVariable String id) {
        VolunteerOrder order = volunteerOrderService.getById(id);
        if (order == null) {
            return Result.error("订单不存在");
        }
        return Result.success(order);
    }
}
