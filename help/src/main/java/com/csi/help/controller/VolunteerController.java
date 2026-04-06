package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.dto.HelpRequestWithDistanceDto;
import com.csi.help.dto.VolunteerStatisticsDto;
import com.csi.help.entity.UserLocation;
import com.csi.help.service.HelpRequestService;
import com.csi.help.service.UserLocationService;
import com.csi.help.service.VolunteerStatisticsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

/**
 * 志愿者端：附近求助等
 */
@RestController
@RequestMapping("/api/volunteer")
@CrossOrigin
public class VolunteerController {

    private static final Logger log = LoggerFactory.getLogger(VolunteerController.class);
    private final HelpRequestService helpRequestService;
    private final UserLocationService userLocationService;
    private final VolunteerStatisticsService volunteerStatisticsService;

    public VolunteerController(HelpRequestService helpRequestService,
                               UserLocationService userLocationService,
                               VolunteerStatisticsService volunteerStatisticsService) {
        this.helpRequestService = helpRequestService;
        this.userLocationService = userLocationService;
        this.volunteerStatisticsService = volunteerStatisticsService;
    }

    /**
     * \u5fd7\u613f\u8005\u4e2a\u4eba\u4e2d\u5fc3\u7edf\u8ba1\uff1a\u670d\u52a1\u6b21\u6570\u3001\u6ee1\u610f\u5ea6\u3001\u670d\u52a1\u65f6\u957f
     */
    @GetMapping("/statistics")
    public Result<VolunteerStatisticsDto> getStatistics(@RequestAttribute("userId") String userId) {
        VolunteerStatisticsDto dto = volunteerStatisticsService.getStatistics(userId);
        return Result.success(dto);
    }

    /**
     * 附近求助列表：按与当前用户（或传入经纬度）距离排序的待接单求助
     * 若不传 latitude/longitude，则使用当前用户最近上报的位置
     */
    @GetMapping("/nearby-requests")
    public Result<PageResult<HelpRequestWithDistanceDto>> getNearbyRequests(
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestAttribute("userId") String userId) {
        Double refLat = latitude;
        Double refLng = longitude;
        if (refLat == null || refLng == null) {
            UserLocation loc = userLocationService.getByUserId(userId);
            if (loc != null) {
                refLat = loc.getLatitude();
                refLng = loc.getLongitude();
            }
        }
        if (refLat == null || refLng == null) {
            log.info("[Volunteer] 附近求助: userId={}, 无位置参数且未上报过位置", userId);
            return Result.error("请先上报位置或传入 latitude、longitude 参数");
        }
        log.info("[Volunteer] 附近求助: userId={}, refLat={}, refLng={}, page={}, pageSize={}", userId, refLat, refLng, page, pageSize);
        PageResult<HelpRequestWithDistanceDto> result =
                helpRequestService.getNearbyRequests(refLat, refLng, page, pageSize);
        log.info("[Volunteer] 附近求助结果: total={}, items={}", result.getTotal(), result.getItems() != null ? result.getItems().size() : 0);
        return Result.success(result);
    }
}
