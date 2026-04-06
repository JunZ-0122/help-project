package com.csi.help.service;

import cn.hutool.core.util.IdUtil;
import com.csi.help.common.PageResult;
import com.csi.help.dto.EmergencyRequestDto;
import com.csi.help.dto.HelpRequestWithDistanceDto;
import com.csi.help.entity.HelpRequest;
import com.csi.help.entity.User;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.mapper.HelpRequestMapper;
import com.csi.help.mapper.UserMapper;
import com.csi.help.mapper.VolunteerOrderMapper;
import com.csi.help.vo.SeekerBannerVo;
import com.csi.help.vo.SeekerRequestDetailVo;
import com.csi.help.vo.SeekerTimelineItemVo;
import com.csi.help.vo.SeekerVolunteerVo;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class HelpRequestService {

    private static final int NEARBY_FETCH_LIMIT = 500;
    private static final DateTimeFormatter HEADER_DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final DateTimeFormatter TIME_ONLY = DateTimeFormatter.ofPattern("HH:mm");

    private final HelpRequestMapper helpRequestMapper;
    private final AmapService amapService;
    private final VolunteerOrderMapper volunteerOrderMapper;
    private final UserMapper userMapper;

    public HelpRequestService(HelpRequestMapper helpRequestMapper, AmapService amapService,
                              VolunteerOrderMapper volunteerOrderMapper, UserMapper userMapper) {
        this.helpRequestMapper = helpRequestMapper;
        this.amapService = amapService;
        this.volunteerOrderMapper = volunteerOrderMapper;
        this.userMapper = userMapper;
    }

    public HelpRequest create(HelpRequest request, String userId, String userName, String userPhone) {
        request.setId(IdUtil.simpleUUID());
        request.setUserId(userId);
        request.setUserName(userName);
        request.setUserPhone(userPhone);
        request.setStatus("pending");
        request.setCreatedAt(LocalDateTime.now());

        // 若有地址但无经纬度，用高德地理编码补全
        if (request.getLocation() != null && !request.getLocation().isBlank()
                && (request.getLatitude() == null || request.getLongitude() == null)) {
            double[] lngLat = amapService.geocode(request.getLocation());
            if (lngLat != null && lngLat.length == 2) {
                request.setLongitude(lngLat[0]);
                request.setLatitude(lngLat[1]);
            }
        }

        helpRequestMapper.insert(request);
        return request;
    }

    public HelpRequest createEmergencyRequest(EmergencyRequestDto request,
                                              String userId,
                                              String userName,
                                              String defaultPhone) {
        HelpRequest emergencyRequest = new HelpRequest();
        emergencyRequest.setType("emergency");
        emergencyRequest.setTitle(buildEmergencyTitle(request.getType()));
        emergencyRequest.setDescription(request.getDescription());
        emergencyRequest.setLocation(request.getLocation());
        emergencyRequest.setUrgency("emergency");
        if (request.getLatitude() != null && request.getLongitude() != null) {
            emergencyRequest.setLatitude(request.getLatitude());
            emergencyRequest.setLongitude(request.getLongitude());
        }

        return create(
                emergencyRequest,
                userId,
                userName,
                resolveContactPhone(request.getContactPhone(), defaultPhone)
        );
    }

    public PageResult<HelpRequest> getRequests(String type, String status, String urgency,
                                               Integer page, Integer pageSize) {
        int offset = (page - 1) * pageSize;
        List<HelpRequest> items = helpRequestMapper.findByPage(type, status, urgency, offset, pageSize);
        Long total = helpRequestMapper.countByCondition(type, status, urgency);

        return new PageResult<>(items, total, page, pageSize);
    }

    public HelpRequest getById(String id) {
        HelpRequest request = helpRequestMapper.findById(id);
        if (request == null) {
            throw new RuntimeException("\u6c42\u52a9\u8bf7\u6c42\u4e0d\u5b58\u5728");
        }
        return request;
    }

    public PageResult<HelpRequest> getMyRequests(String userId, Integer page, Integer pageSize) {
        int offset = (page - 1) * pageSize;
        List<HelpRequest> items = helpRequestMapper.findByUserId(userId, offset, pageSize);
        Long total = helpRequestMapper.countByUserId(userId);

        return new PageResult<>(items, total, page, pageSize);
    }

    /**
     * 首页「最近求助」：按最近更新时间取前几条
     */
    public List<HelpRequest> getRecentMyRequests(String userId, int limit) {
        int n = limit;
        if (n < 1) {
            n = 3;
        }
        if (n > 50) {
            n = 50;
        }
        return helpRequestMapper.findRecentByUserId(userId, n);
    }

    public HelpRequest update(String id, HelpRequest request) {
        HelpRequest existing = getById(id);

        if (request.getTitle() != null) {
            existing.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            existing.setDescription(request.getDescription());
        }
        if (request.getLocation() != null) {
            existing.setLocation(request.getLocation());
        }
        if (request.getLatitude() != null) {
            existing.setLatitude(request.getLatitude());
        }
        if (request.getLongitude() != null) {
            existing.setLongitude(request.getLongitude());
        }
        if (request.getUrgency() != null) {
            existing.setUrgency(request.getUrgency());
        }
        if (request.getScheduledTime() != null) {
            existing.setScheduledTime(request.getScheduledTime());
        }
        if (request.getImages() != null) {
            existing.setImages(request.getImages());
        }

        existing.setUpdatedAt(LocalDateTime.now());
        helpRequestMapper.update(existing);

        return existing;
    }

    public void cancel(String id) {
        helpRequestMapper.delete(id);
    }

    public void assignVolunteer(String requestId, String volunteerId, String volunteerName) {
        helpRequestMapper.assignVolunteer(requestId, volunteerId, volunteerName);
        helpRequestMapper.updateStatus(requestId, "assigned");
    }

    private String resolveContactPhone(String contactPhone, String defaultPhone) {
        if (contactPhone != null && !contactPhone.trim().isEmpty()) {
            return contactPhone.trim();
        }
        return defaultPhone;
    }

    private String buildEmergencyTitle(String type) {
        switch (type) {
            case "medical":
                return "\u533b\u7597\u6025\u6551";
            case "safety":
                return "\u5b89\u5168\u6c42\u52a9";
            case "accident":
                return "\u610f\u5916\u4e8b\u6545";
            case "other":
                return "\u5176\u4ed6\u7d27\u6025\u6c42\u52a9";
            default:
                return "\u7d27\u6025\u6c42\u52a9";
        }
    }

    /**
     * 附近求助：按与参考点距离排序的待接单列表（仅含已有经纬度的求助）
     */
    public PageResult<HelpRequestWithDistanceDto> getNearbyRequests(Double refLat, Double refLng,
                                                                   Integer page, Integer pageSize) {
        List<HelpRequest> pending = helpRequestMapper.findPendingWithLocation(0, NEARBY_FETCH_LIMIT);
        if (pending.isEmpty()) {
            return new PageResult<>(new ArrayList<>(), 0L, page, pageSize);
        }
        double refLatD = refLat != null ? refLat : 0.0;
        double refLngD = refLng != null ? refLng : 0.0;

        List<HelpRequestWithDistanceDto> withDistance = pending.stream()
                .filter(r -> r.getLatitude() != null && r.getLongitude() != null)
                .map(r -> {
                    double km = AmapService.distanceKm(
                            r.getLongitude(), r.getLatitude(), refLngD, refLatD);
                    return new HelpRequestWithDistanceDto(r, km);
                })
                .sorted(Comparator.comparingDouble(HelpRequestWithDistanceDto::getDistance))
                .collect(Collectors.toList());

        long total = withDistance.size();
        int from = (page - 1) * pageSize;
        int to = Math.min(from + pageSize, withDistance.size());
        List<HelpRequestWithDistanceDto> pageItems = from < withDistance.size()
                ? withDistance.subList(from, to)
                : new ArrayList<>();
        return new PageResult<>(pageItems, total, page, pageSize);
    }

    /**
     * 求助者本人：详情页聚合（时间线、横幅、志愿者距离与电话等）
     */
    public SeekerRequestDetailVo getSeekerRequestDetail(String requestId, String userId) {
        HelpRequest r = helpRequestMapper.findById(requestId);
        if (r == null) {
            throw new RuntimeException("\u6c42\u52a9\u8bf7\u6c42\u4e0d\u5b58\u5728");
        }
        if (!userId.equals(r.getUserId())) {
            throw new RuntimeException("\u65e0\u6743\u67e5\u770b\u8be5\u6c42\u52a9");
        }

        VolunteerOrder order = volunteerOrderMapper.findByRequestId(requestId);
        SeekerRequestDetailVo vo = new SeekerRequestDetailVo();
        vo.setRequest(r);
        vo.setHeaderTimeDisplay(r.getCreatedAt() != null ? r.getCreatedAt().format(HEADER_DT) : "");

        String st = r.getStatus();
        switch (st) {
            case "pending":
                vo.setBadgeLabel("\u5df2\u53d1\u5e03");
                vo.setBadgeTone("published");
                break;
            case "assigned":
                vo.setBadgeLabel("\u5df2\u63a5\u5355");
                vo.setBadgeTone("accepted");
                break;
            case "in-progress":
                vo.setBadgeLabel("\u5fd7\u613f\u8005\u5df2\u51fa\u53d1");
                vo.setBadgeTone("departed");
                break;
            case "completed":
                vo.setBadgeLabel("\u5df2\u5b8c\u6210");
                vo.setBadgeTone("completed");
                break;
            case "cancelled":
                vo.setBadgeLabel("\u5df2\u53d6\u6d88");
                vo.setBadgeTone("cancelled");
                break;
            default:
                vo.setBadgeLabel("\u5df2\u53d1\u5e03");
                vo.setBadgeTone("published");
        }

        if ("pending".equals(st)) {
            SeekerBannerVo b = new SeekerBannerVo();
            b.setTone("blue");
            b.setTitle("\u6b63\u5728\u4e3a\u60a8\u5339\u914d\u5fd7\u613f\u8005...");
            b.setSubtitle("\u8bf7\u8010\u5fc3\u7b49\u5f85\uff0c\u6211\u4eec\u4f1a\u5c3d\u5feb\u5b89\u6392");
            vo.setBanner(b);
        } else if ("in-progress".equals(st)) {
            int eta = 5;
            if (order != null && order.getEstimatedDuration() != null && order.getEstimatedDuration() > 0) {
                eta = order.getEstimatedDuration();
            }
            vo.setEtaMinutes(eta);
            SeekerBannerVo b = new SeekerBannerVo();
            b.setTone("orange");
            b.setTitle("\u5fd7\u613f\u8005\u6b63\u5728\u524d\u5f80\uff0c\u9884\u8ba1 " + eta + " \u5206\u949f\u5230\u8fbe");
            b.setSubtitle("\u8bf7\u4fdd\u6301\u624b\u673a\u7545\u901a");
            vo.setBanner(b);
        }

        if (r.getVolunteerId() != null
                && ("assigned".equals(st) || "in-progress".equals(st) || "completed".equals(st))) {
            vo.setVolunteer(buildSeekerVolunteer(r, order));
        }

        vo.setTimeline(buildSeekerTimeline(r, order, st));
        return vo;
    }

    private SeekerVolunteerVo buildSeekerVolunteer(HelpRequest r, VolunteerOrder order) {
        User u = userMapper.findById(r.getVolunteerId());
        SeekerVolunteerVo v = new SeekerVolunteerVo();
        v.setId(r.getVolunteerId());
        v.setName(r.getVolunteerName() != null ? r.getVolunteerName() : "\u5fd7\u613f\u8005");
        if (u != null) {
            if (u.getName() != null && !u.getName().isEmpty()) {
                v.setName(u.getName());
            }
            String phone = u.getPhone();
            v.setPhone(phone);
            v.setPhoneMasked(maskPhone(phone));
            v.setAvatarUrl(u.getAvatar());
        } else {
            v.setPhoneMasked("");
        }
        if (order != null && order.getDistance() != null) {
            v.setDistanceKm(round1(order.getDistance()));
        }
        return v;
    }

    private static double round1(double d) {
        return Math.round(d * 10.0) / 10.0;
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone == null ? "" : phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    private List<SeekerTimelineItemVo> buildSeekerTimeline(HelpRequest r, VolunteerOrder order, String st) {
        List<SeekerTimelineItemVo> list = new ArrayList<>();
        if ("cancelled".equals(st)) {
            SeekerTimelineItemVo a = new SeekerTimelineItemVo();
            a.setLabel("\u53d1\u5e03\u6c42\u52a9");
            a.setTime(r.getCreatedAt() != null ? r.getCreatedAt().format(TIME_ONLY) : "");
            a.setState("done");
            list.add(a);
            SeekerTimelineItemVo b = new SeekerTimelineItemVo();
            b.setLabel("\u6c42\u52a9\u5df2\u53d6\u6d88");
            b.setTime(r.getUpdatedAt() != null ? r.getUpdatedAt().format(TIME_ONLY) : "");
            b.setState("current");
            list.add(b);
            return list;
        }

        LocalDateTime t0 = r.getCreatedAt();
        LocalDateTime t1 = order != null ? order.getAcceptedAt() : null;
        if (t1 == null && order != null) {
            t1 = order.getCreatedAt();
        }
        LocalDateTime t2 = order != null ? order.getStartedAt() : null;
        if (t2 == null && order != null) {
            t2 = order.getUpdatedAt();
        }
        LocalDateTime t3 = order != null && order.getCompletedAt() != null
                ? order.getCompletedAt() : r.getCompletedAt();
        if ("completed".equals(st) && t3 == null) {
            t3 = r.getUpdatedAt() != null ? r.getUpdatedAt() : r.getCreatedAt();
        }

        String s0;
        String s1;
        String s2;
        String s3;
        if ("pending".equals(st)) {
            s0 = "current";
            s1 = "upcoming";
            s2 = "upcoming";
            s3 = "upcoming";
        } else if ("assigned".equals(st)) {
            s0 = "done";
            s1 = "current";
            s2 = "upcoming";
            s3 = "upcoming";
        } else if ("in-progress".equals(st)) {
            s0 = "done";
            s1 = "done";
            s2 = "current";
            s3 = "upcoming";
        } else {
            s0 = "done";
            s1 = "done";
            s2 = "done";
            s3 = "done";
        }

        list.add(item("\u53d1\u5e03\u6c42\u52a9", t0, s0));
        list.add(item("\u5fd7\u613f\u8005\u63a5\u5355", t1, s1));
        list.add(item("\u5fd7\u613f\u8005\u5df2\u51fa\u53d1", t2, s2));
        list.add(item("\u670d\u52a1\u5b8c\u6210", t3, s3));
        return list;
    }

    private static SeekerTimelineItemVo item(String label, LocalDateTime t, String state) {
        SeekerTimelineItemVo x = new SeekerTimelineItemVo();
        x.setLabel(label);
        x.setTime(t != null ? t.format(TIME_ONLY) : "");
        x.setState(state);
        return x;
    }
}
