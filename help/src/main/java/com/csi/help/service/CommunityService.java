package com.csi.help.service;

import com.csi.help.common.PageResult;
import com.csi.help.dto.CommunityVolunteerDto;
import com.csi.help.dto.DispatchScoredRequestDto;
import com.csi.help.dto.DispatchVolunteerProfileDto;
import com.csi.help.dto.QuickDispatchResponseDto;
import com.csi.help.dto.VolunteerManagementResponseDto;
import com.csi.help.dto.VolunteerManagementRowDto;
import com.csi.help.dto.VolunteerManagementSummaryDto;
import com.csi.help.dto.VolunteerSkillTagDto;
import com.csi.help.entity.HelpRequest;
import com.csi.help.entity.User;
import com.csi.help.entity.UserLocation;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.mapper.HelpRequestMapper;
import com.csi.help.mapper.ReviewMapper;
import com.csi.help.mapper.UserMapper;
import com.csi.help.mapper.VolunteerOrderMapper;
import com.csi.help.mapper.VolunteerSkillMapper;
import com.csi.help.service.AmapService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class CommunityService {

    @Autowired
    private HelpRequestMapper helpRequestMapper;

    @Autowired
    private VolunteerOrderService volunteerOrderService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private UserLocationService userLocationService;

    @Autowired
    private VolunteerOrderMapper volunteerOrderMapper;

    @Autowired
    private ReviewMapper reviewMapper;

    @Autowired
    private VolunteerSkillMapper volunteerSkillMapper;

    public PageResult<HelpRequest> getAllRequests(Integer page, Integer pageSize, String status) {
        if (pageSize == null || pageSize < 1) {
            pageSize = 20;
        }
        if (pageSize > 200) {
            pageSize = 200;
        }
        if (page == null || page < 1) {
            page = 1;
        }
        int offset = (page - 1) * pageSize;

        if (status == null || status.isBlank() || "all".equalsIgnoreCase(status)) {
            Long total = helpRequestMapper.countCommunity("all");
            List<HelpRequest> requests = helpRequestMapper.findAllCommunity(offset, pageSize, "all");
            return new PageResult<>(requests, total, page, pageSize);
        }
        if ("pending".equals(status)) {
            Long total = helpRequestMapper.countCommunity("pending");
            List<HelpRequest> requests = helpRequestMapper.findAllCommunity(offset, pageSize, "pending");
            return new PageResult<>(requests, total, page, pageSize);
        }
        if ("assigned".equals(status)) {
            Long total = helpRequestMapper.countCommunity("assigned_open");
            List<HelpRequest> requests = helpRequestMapper.findAllCommunity(offset, pageSize, "assigned_open");
            return new PageResult<>(requests, total, page, pageSize);
        }

        Long total = helpRequestMapper.count(status);
        List<HelpRequest> requests = helpRequestMapper.findAll(offset, pageSize, status);
        return new PageResult<>(requests, total, page, pageSize);
    }

    /**
     * 获取可用志愿者列表。若传入 requestId 或 latitude+longitude，则按与参考点距离排序。
     */
    public List<CommunityVolunteerDto> getAvailableVolunteers(String requestId, Double latitude, Double longitude) {
        List<User> volunteers = userMapper.findByRole("volunteer");
        List<CommunityVolunteerDto> result = new ArrayList<>();

        double refLat = 0.0, refLng = 0.0;
        boolean hasRef = false;
        if (requestId != null && !requestId.isBlank()) {
            HelpRequest request = helpRequestMapper.findById(requestId);
            if (request != null && request.getLatitude() != null && request.getLongitude() != null) {
                refLat = request.getLatitude();
                refLng = request.getLongitude();
                hasRef = true;
            }
        }
        if (!hasRef && latitude != null && longitude != null) {
            refLat = latitude;
            refLng = longitude;
            hasRef = true;
        }

        for (User volunteer : volunteers) {
            List<VolunteerOrder> orders = volunteerOrderService.getMyOrders(volunteer.getId(), null);
            int currentOrders = countCurrentOrders(orders);
            int completedOrders = countCompletedOrders(orders);
            String availability = getAvailabilityStatus(volunteer, currentOrders);

            if (!"available".equals(availability)) {
                continue;
            }

            CommunityVolunteerDto volunteerDto = new CommunityVolunteerDto();
            volunteerDto.setId(volunteer.getId());
            volunteerDto.setName(volunteer.getName());
            volunteerDto.setPhone(volunteer.getPhone());
            volunteerDto.setAvatar(volunteer.getAvatar());
            volunteerDto.setStatus(availability);
            volunteerDto.setRating(volunteer.getRating() == null ? 0.0 : volunteer.getRating());
            volunteerDto.setCompletedOrders(completedOrders);
            volunteerDto.setCurrentOrders(currentOrders);
            volunteerDto.setLocation(volunteer.getAddress());

            if (hasRef) {
                UserLocation loc = userLocationService.getByUserId(volunteer.getId());
                if (loc != null && loc.getLatitude() != null && loc.getLongitude() != null) {
                    double km = AmapService.distanceKm(
                            loc.getLongitude(), loc.getLatitude(), refLng, refLat);
                    volunteerDto.setDistance(km);
                } else {
                    volunteerDto.setDistance(null);
                }
            } else {
                volunteerDto.setDistance(0.0);
            }
            result.add(volunteerDto);
        }

        if (hasRef) {
            result.sort(Comparator.comparing(
                    CommunityVolunteerDto::getDistance,
                    Comparator.nullsLast(Comparator.naturalOrder())));
        }
        return result;
    }

    @Transactional
    public VolunteerOrder assignVolunteer(String requestId, String volunteerId) {
        return volunteerOrderService.acceptOrder(requestId, volunteerId);
    }

    public Map<String, Object> getStatistics() {
        Map<String, Object> stats = new HashMap<>();
        List<User> volunteers = userMapper.findByRole("volunteer");
        List<HelpRequest> allRequests = helpRequestMapper.findAll(0, 1000, null);

        int totalVolunteers = volunteers.size();
        int availableVolunteers = 0;
        int busyVolunteers = 0;

        for (User volunteer : volunteers) {
            List<VolunteerOrder> orders = volunteerOrderService.getMyOrders(volunteer.getId(), null);
            int currentOrders = countCurrentOrders(orders);
            String availability = getAvailabilityStatus(volunteer, currentOrders);
            if ("available".equals(availability)) {
                availableVolunteers++;
            }
            if ("busy".equals(availability)) {
                busyVolunteers++;
            }
        }

        long totalRequests = helpRequestMapper.count(null);
        long pendingRequests = helpRequestMapper.count("pending");
        long assignedRequests = helpRequestMapper.count("assigned");
        long inProgressRequests = helpRequestMapper.count("in-progress");
        long completedRequests = helpRequestMapper.count("completed");

        int todayRequests = 0;
        int todayCompleted = 0;
        for (HelpRequest request : allRequests) {
            if (request.getCreatedAt() != null && request.getCreatedAt().toLocalDate().equals(LocalDate.now())) {
                todayRequests++;
            }
            if (request.getCompletedAt() != null && request.getCompletedAt().toLocalDate().equals(LocalDate.now())) {
                todayCompleted++;
            }
        }

        double satisfactionRateLegacy = totalRequests == 0 ? 0.0 : (completedRequests * 100.0 / totalRequests);

        stats.put("totalRequests", totalRequests);
        stats.put("pendingRequests", pendingRequests);
        stats.put("assignedRequests", assignedRequests);
        stats.put("inProgressRequests", inProgressRequests);
        stats.put("completedRequests", completedRequests);
        stats.put("totalVolunteers", totalVolunteers);
        stats.put("availableVolunteers", availableVolunteers);
        stats.put("busyVolunteers", busyVolunteers);
        stats.put("todayRequests", todayRequests);
        stats.put("todayCompleted", todayCompleted);
        stats.put("averageResponseTime", 0);
        stats.put("averageCompletionTime", 0);
        stats.put("satisfactionRate", satisfactionRateLegacy);

        LocalDate today = LocalDate.now();
        LocalDate firstOfMonth = today.with(TemporalAdjusters.firstDayOfMonth());
        LocalDateTime monthStart = firstOfMonth.atStartOfDay();
        LocalDateTime monthEnd = firstOfMonth.plusMonths(1).atStartOfDay();
        LocalDateTime prevMonthStart = firstOfMonth.minusMonths(1).atStartOfDay();
        LocalDateTime prevMonthEnd = firstOfMonth.atStartOfDay();

        long monthlyHelpCount = volunteerOrderMapper.countCompletedBetween(monthStart, monthEnd);
        long prevMonthlyHelpCount = volunteerOrderMapper.countCompletedBetween(prevMonthStart, prevMonthEnd);
        stats.put("monthlyHelpCount", monthlyHelpCount);
        stats.put("monthlyHelpTrendPercent", percentChange(monthlyHelpCount, prevMonthlyHelpCount));

        Double avgRatingMonth = reviewMapper.avgRatingCreatedBetween(monthStart, monthEnd);
        Double avgRatingPrev = reviewMapper.avgRatingCreatedBetween(prevMonthStart, prevMonthEnd);
        int satisfactionPercent = ratingToPercent(avgRatingMonth);
        int satisfactionPrevPercent = ratingToPercent(avgRatingPrev);
        stats.put("monthlySatisfactionPercent", satisfactionPercent);
        stats.put("monthlySatisfactionDeltaPoints", satisfactionPercent - satisfactionPrevPercent);

        long activeVolunteersMonth = volunteerOrderMapper.countDistinctVolunteersCompletedBetween(monthStart, monthEnd);
        long activeVolunteersPrev = volunteerOrderMapper.countDistinctVolunteersCompletedBetween(prevMonthStart, prevMonthEnd);
        stats.put("activeVolunteersMonth", activeVolunteersMonth);
        stats.put("activeVolunteersTrendPercent", percentChange(activeVolunteersMonth, activeVolunteersPrev));
        stats.put("activeVolunteersMomDelta", activeVolunteersMonth - activeVolunteersPrev);

        stats.put("requestTypes", buildMonthlyRequestTypeStats(monthStart, monthEnd));
        stats.put("weeklyTrend", buildWeeklyCompletionTrend());
        stats.put("topVolunteers", buildTopVolunteersThisMonth(monthStart, monthEnd));

        return stats;
    }

    private static int percentChange(long current, long previous) {
        if (previous <= 0) {
            return current > 0 ? 100 : 0;
        }
        return (int) Math.round((current - previous) * 100.0 / previous);
    }

    private static int ratingToPercent(Double avgRating) {
        if (avgRating == null || avgRating <= 0) {
            return 0;
        }
        return (int) Math.round(avgRating * 20.0);
    }

    /**
     * \u672c\u6708\u6536\u5230\u7684\u8bc4\u4ef7\u4f18\u5148\uff1b\u65e0\u5219\u5168\u91cf\u5747\u5206\uff1b\u518d\u65e0\u5219\u7528\u7528\u6237\u8868\u7efc\u5408\u8bc4\u5206\u3002
     */
    private int satisfactionPercentForVolunteer(String volunteerId, User user,
                                                LocalDateTime monthStart, LocalDateTime monthEnd) {
        Double avgMonth = reviewMapper.avgRatingByRevieweeIdBetween(volunteerId, monthStart, monthEnd);
        if (avgMonth != null && avgMonth > 0) {
            return ratingToPercent(avgMonth);
        }
        Double avg = reviewMapper.avgRatingByRevieweeId(volunteerId);
        if (avg != null && avg > 0) {
            return ratingToPercent(avg);
        }
        if (user != null && user.getRating() != null) {
            return (int) Math.round(user.getRating() * 20.0);
        }
        return 0;
    }

    private List<Map<String, Object>> buildMonthlyRequestTypeStats(LocalDateTime monthStart, LocalDateTime monthEnd) {
        List<Map<String, Object>> rows = helpRequestMapper.countByTypeCreatedBetween(monthStart, monthEnd);
        if (rows == null) {
            rows = new ArrayList<>();
        }
        Map<String, Integer> raw = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String type = row.get("type") != null ? row.get("type").toString() : "other";
            Number cn = pickMapNumber(row, "cnt", "CNT");
            int cnt = cn != null ? cn.intValue() : 0;
            raw.put(type, raw.getOrDefault(type, 0) + cnt);
        }
        int medical = raw.getOrDefault("medical", 0) + raw.getOrDefault("emergency", 0);
        int travel = raw.getOrDefault("companion", 0);
        int life = raw.getOrDefault("shopping", 0);
        int companionSvc = raw.getOrDefault("repair", 0);
        int other = raw.getOrDefault("other", 0);

        List<Map<String, Object>> buckets = new ArrayList<>();
        buckets.add(categoryBucket("\u5c31\u533b\u534f\u52a9", "cat_medical", medical));
        buckets.add(categoryBucket("\u51fa\u884c\u534f\u52a9", "cat_travel", travel));
        buckets.add(categoryBucket("\u751f\u6d3b\u5e2e\u6276", "cat_life", life));
        buckets.add(categoryBucket("\u966a\u4f34\u670d\u52a1", "cat_companion", companionSvc));
        buckets.add(categoryBucket("\u5176\u4ed6", "cat_other", other));

        int total = buckets.stream().mapToInt(b -> (Integer) b.get("count")).sum();
        buckets.sort(Comparator.comparingInt((Map<String, Object> b) -> (Integer) b.get("count")).reversed());

        List<Map<String, Object>> result = new ArrayList<>();
        int rank = 1;
        for (Map<String, Object> b : buckets) {
            int count = (Integer) b.get("count");
            Map<String, Object> item = new HashMap<>();
            item.put("rank", rank++);
            item.put("name", b.get("name"));
            item.put("type", b.get("type"));
            item.put("count", count);
            item.put("percentage", total == 0 ? 0 : (int) Math.round(count * 100.0 / total));
            result.add(item);
        }
        return result;
    }

    private Map<String, Object> categoryBucket(String name, String typeKey, int count) {
        Map<String, Object> m = new HashMap<>();
        m.put("name", name);
        m.put("type", typeKey);
        m.put("count", count);
        return m;
    }

    private List<Map<String, Object>> buildWeeklyCompletionTrend() {
        LocalDate today = LocalDate.now();
        LocalDate monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        List<Map<String, Object>> trend = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            LocalDate d = monday.plusDays(i);
            long count = volunteerOrderMapper.countCompletedOnLocalDate(d);
            Map<String, Object> dayData = new HashMap<>();
            dayData.put("date", d.toString());
            dayData.put("dayOfWeek", dayOfWeekCn(d.getDayOfWeek().getValue()));
            dayData.put("count", count);
            trend.add(dayData);
        }
        return trend;
    }

    private String dayOfWeekCn(int isoDow) {
        switch (isoDow) {
            case 1: return "\u5468\u4e00";
            case 2: return "\u5468\u4e8c";
            case 3: return "\u5468\u4e09";
            case 4: return "\u5468\u56db";
            case 5: return "\u5468\u4e94";
            case 6: return "\u5468\u516d";
            case 7: return "\u5468\u65e5";
            default: return "";
        }
    }

    /**
     * 优秀志愿者：先按本月完成单数降序，单数相同再按满意度降序，避免仅 SQL 按 cnt 排序时并列名次不确定。
     */
    private List<Map<String, Object>> buildTopVolunteersThisMonth(LocalDateTime monthStart, LocalDateTime monthEnd) {
        List<Map<String, Object>> rows = volunteerOrderMapper.volunteerCompletedCountsBetween(monthStart, monthEnd, 100);
        if (rows == null) {
            rows = new ArrayList<>();
        }
        List<Map<String, Object>> enriched = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            String vid = pickMapStr(row, "volunteerId", "volunteer_id");
            String vname = pickMapStr(row, "volunteerName", "volunteer_name");
            Number cntNum = pickMapNumber(row, "cnt", "CNT");
            int cnt = cntNum != null ? cntNum.intValue() : 0;
            if (vid == null || vid.isEmpty()) {
                continue;
            }
            User u = userMapper.findById(vid);
            if (u != null && vname != null && !vname.isEmpty() && u.getName() != null
                    && !vname.equals(u.getName())) {
                vname = u.getName();
            }
            int sat = satisfactionPercentForVolunteer(vid, u, monthStart, monthEnd);
            Map<String, Object> m = new HashMap<>();
            m.put("id", vid);
            m.put("name", vname != null ? vname : "");
            m.put("avatar", u != null ? u.getAvatar() : null);
            m.put("serviceCount", cnt);
            m.put("satisfaction", sat);
            enriched.add(m);
        }

        enriched.sort((a, b) -> {
            int ca = (Integer) a.get("serviceCount");
            int cb = (Integer) b.get("serviceCount");
            if (ca != cb) {
                return Integer.compare(cb, ca);
            }
            int sa = (Integer) a.get("satisfaction");
            int sb = (Integer) b.get("satisfaction");
            if (sa != sb) {
                return Integer.compare(sb, sa);
            }
            String na = (String) a.get("name");
            String nb = (String) b.get("name");
            if (na == null) {
                na = "";
            }
            if (nb == null) {
                nb = "";
            }
            return na.compareTo(nb);
        });

        List<Map<String, Object>> result = new ArrayList<>();
        int rank = 1;
        for (int i = 0; i < enriched.size() && i < 3; i++) {
            Map<String, Object> src = enriched.get(i);
            Map<String, Object> item = new HashMap<>();
            item.put("rank", rank++);
            item.put("id", src.get("id"));
            item.put("name", src.get("name"));
            item.put("avatar", src.get("avatar"));
            item.put("serviceCount", src.get("serviceCount"));
            item.put("satisfaction", src.get("satisfaction"));
            result.add(item);
        }
        return result;
    }

    private static String pickMapStr(Map<String, Object> row, String a, String b) {
        Object v = row.get(a);
        if (v == null) {
            v = row.get(b);
        }
        return v != null ? v.toString() : null;
    }

    private static Number pickMapNumber(Map<String, Object> row, String a, String b) {
        Object v = row.get(a);
        if (v == null) {
            v = row.get(b);
        }
        return v instanceof Number ? (Number) v : null;
    }

    @Transactional
    public void reviewRequest(String requestId, String status) {
        if (!"approved".equals(status) && !"rejected".equals(status)) {
            throw new IllegalArgumentException("\u65e0\u6548\u7684\u5ba1\u6838\u72b6\u6001");
        }
        helpRequestMapper.updateStatus(requestId, status);
    }

    private int countCurrentOrders(List<VolunteerOrder> orders) {
        int count = 0;
        for (VolunteerOrder order : orders) {
            if ("accepted".equals(order.getStatus()) || "in-progress".equals(order.getStatus())) {
                count++;
            }
        }
        return count;
    }

    private int countCompletedOrders(List<VolunteerOrder> orders) {
        int count = 0;
        for (VolunteerOrder order : orders) {
            if ("completed".equals(order.getStatus())) {
                count++;
            }
        }
        return count;
    }

    private String getAvailabilityStatus(User volunteer, int currentOrders) {
        if (currentOrders > 0) {
            return "busy";
        }
        if ("online".equals(volunteer.getStatus())) {
            return "available";
        }
        return "offline";
    }

    /**
     * 社区端「志愿者管理」页：汇总 + 全量志愿者列表（可搜索）
     */
    public VolunteerManagementResponseDto getVolunteerManagementPage(String keyword) {
        VolunteerManagementResponseDto out = new VolunteerManagementResponseDto();
        List<User> volunteers = userMapper.findByRole("volunteer");
        LocalDate today = LocalDate.now();
        LocalDate monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDateTime weekStart = monday.atStartOfDay();
        LocalDateTime weekEnd = monday.plusWeeks(1).atStartOfDay();
        long weekServices = volunteerOrderMapper.countCompletedBetween(weekStart, weekEnd);

        int onlineCnt = 0;
        int inServiceCnt = 0;
        double ratingSum = 0;
        int ratingN = 0;
        List<VolunteerManagementRowDto> rows = new ArrayList<>();

        for (User v : volunteers) {
            List<VolunteerOrder> orders = volunteerOrderService.getMyOrders(v.getId(), null);
            int currentOrders = countCurrentOrders(orders);
            int completed = countCompletedOrders(orders);
            String avail = getAvailabilityStatus(v, currentOrders);
            if ("available".equals(avail)) {
                onlineCnt++;
            }
            if ("busy".equals(avail)) {
                inServiceCnt++;
            }
            if (v.getRating() != null) {
                ratingSum += v.getRating();
                ratingN++;
            }

            VolunteerManagementRowDto row = new VolunteerManagementRowDto();
            row.setId(v.getId());
            row.setName(v.getName());
            row.setAvatar(v.getAvatar());
            row.setPhoneMasked(maskPhone(v.getPhone()));
            row.setLocation(v.getAddress() != null ? v.getAddress() : "");
            if ("busy".equals(avail)) {
                row.setUiStatus("in_service");
            } else if ("available".equals(avail)) {
                row.setUiStatus("online");
            } else {
                row.setUiStatus("offline");
            }
            row.setServiceCount(completed);
            row.setSatisfaction(satisfactionPercentAllTime(v.getId(), v));
            row.setSkills(buildVolunteerSkillTags(resolveSkillCodesForVolunteer(v.getId())));
            row.setQuickDispatchEnabled("available".equals(avail));
            rows.add(row);
        }

        String kw = keyword == null ? "" : keyword.trim().toLowerCase(Locale.ROOT);
        if (!kw.isEmpty()) {
            List<VolunteerManagementRowDto> filtered = new ArrayList<>();
            for (VolunteerManagementRowDto row : rows) {
                if (matchesVolunteerKeyword(row, kw)) {
                    filtered.add(row);
                }
            }
            rows = filtered;
        }

        VolunteerManagementSummaryDto summary = new VolunteerManagementSummaryDto();
        summary.setTotalVolunteers(volunteers.size());
        summary.setOnlineCount(onlineCnt);
        summary.setInServiceCount(inServiceCnt);
        summary.setWeekServices(weekServices);
        summary.setAvgRating(ratingN > 0 ? Math.round(ratingSum * 10.0 / ratingN) / 10.0 : 0.0);

        out.setSummary(summary);
        out.setVolunteers(rows);
        return out;
    }

    /**
     * 快速派单：按技能匹配度、距离、紧急程度、志愿者历史评分综合打分（0–100），并拆分智能推荐与其它待派单。
     */
    public QuickDispatchResponseDto getQuickDispatchRecommendations(String volunteerId) {
        User volunteer = userMapper.findById(volunteerId);
        if (volunteer == null || !"volunteer".equals(volunteer.getRole())) {
            throw new IllegalArgumentException("\u5fd7\u613f\u8005\u4e0d\u5b58\u5728");
        }
        List<String> skillCodes = resolveSkillCodesForVolunteer(volunteerId);
        UserLocation vLoc = userLocationService.getByUserId(volunteerId);
        Double vLat = vLoc != null ? vLoc.getLatitude() : null;
        Double vLng = vLoc != null ? vLoc.getLongitude() : null;

        DispatchVolunteerProfileDto profile = new DispatchVolunteerProfileDto();
        profile.setId(volunteer.getId());
        profile.setName(volunteer.getName());
        profile.setAvatar(volunteer.getAvatar());
        profile.setLocation(volunteer.getAddress() != null ? volunteer.getAddress() : "");
        profile.setSatisfaction(satisfactionPercentAllTime(volunteerId, volunteer));
        profile.setSkills(buildVolunteerSkillTags(skillCodes));

        List<HelpRequest> pending = helpRequestMapper.findAllPendingForDispatch(200);
        if (pending == null) {
            pending = new ArrayList<>();
        }

        List<DispatchScoredRequestDto> smart = new ArrayList<>();
        List<DispatchScoredRequestDto> other = new ArrayList<>();
        for (HelpRequest r : pending) {
            boolean matched = skillMatches(skillCodes, r.getType());
            int score = computeDispatchMatchScore(r, skillCodes, vLat, vLng, volunteer);
            Double distKm = computeDistanceKm(r, vLat, vLng);
            DispatchScoredRequestDto dto = toDispatchScoredDto(r, score, distKm, matched);
            if (matched) {
                smart.add(dto);
            } else {
                other.add(dto);
            }
        }

        Comparator<DispatchScoredRequestDto> cmp = Comparator
                .comparingInt(DispatchScoredRequestDto::getMatchScore).reversed()
                .thenComparing(DispatchScoredRequestDto::getCreatedAt,
                        Comparator.nullsLast(Comparator.reverseOrder()));
        smart.sort(cmp);
        other.sort(cmp);

        QuickDispatchResponseDto res = new QuickDispatchResponseDto();
        res.setVolunteer(profile);
        res.setSmartMatches(smart);
        res.setOtherPending(other);
        return res;
    }

    private static boolean matchesVolunteerKeyword(VolunteerManagementRowDto row, String kw) {
        if (row.getName() != null && row.getName().toLowerCase(Locale.ROOT).contains(kw)) {
            return true;
        }
        if (row.getSkills() != null) {
            for (VolunteerSkillTagDto t : row.getSkills()) {
                if (t.getLabel() != null && t.getLabel().toLowerCase(Locale.ROOT).contains(kw)) {
                    return true;
                }
                if (t.getCode() != null && t.getCode().toLowerCase(Locale.ROOT).contains(kw)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * 优先读 volunteer_skills；表未迁移或查询失败时，用已完成订单的 type 推断，避免接口 500。
     */
    private List<String> resolveSkillCodesForVolunteer(String volunteerId) {
        List<String> fromTable = null;
        try {
            fromTable = volunteerSkillMapper.findSkillCodesByUserId(volunteerId);
        } catch (DataAccessException ignored) {
            // 常见原因：未执行 migration-volunteer-skills.sql，表 volunteer_skills 不存在
        }
        if (fromTable != null && !fromTable.isEmpty()) {
            return new ArrayList<>(fromTable);
        }
        List<String> fromOrders = volunteerOrderMapper.findDistinctCompletedTypesByVolunteer(volunteerId);
        return fromOrders != null ? new ArrayList<>(fromOrders) : new ArrayList<>();
    }

    private List<VolunteerSkillTagDto> buildVolunteerSkillTags(List<String> codes) {
        List<VolunteerSkillTagDto> list = new ArrayList<>();
        if (codes == null) {
            return list;
        }
        LinkedHashMap<String, Boolean> seen = new LinkedHashMap<>();
        for (String c : codes) {
            if (c != null && !c.isBlank() && !seen.containsKey(c)) {
                seen.put(c, Boolean.TRUE);
                VolunteerSkillTagDto t = new VolunteerSkillTagDto();
                t.setCode(c);
                t.setLabel(skillLabelForCode(c));
                list.add(t);
            }
        }
        return list;
    }

    private static String skillLabelForCode(String code) {
        if (code == null) {
            return "";
        }
        switch (code) {
            case "medical":
                return "\u5c31\u533b\u534f\u52a9";
            case "companion":
                return "\u51fa\u884c\u534f\u52a9";
            case "shopping":
                return "\u751f\u6d3b\u5e2e\u6276";
            case "repair":
                return "\u7ef4\u4fee\u534f\u52a9";
            case "emergency":
                return "\u7d27\u6025\u6551\u63f4";
            case "other":
            default:
                return "\u5176\u4ed6";
        }
    }

    private static String requestTypeLabel(String type) {
        return skillLabelForCode(type != null ? type : "other");
    }

    private static boolean skillMatches(List<String> skills, String requestType) {
        if (skills == null || skills.isEmpty() || requestType == null) {
            return false;
        }
        if (skills.contains(requestType)) {
            return true;
        }
        return "emergency".equals(requestType)
                && (skills.contains("emergency") || skills.contains("medical"));
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone != null ? phone : "";
        }
        int n = phone.length();
        int keepEnd = Math.min(4, n - 3);
        int prefixLen = Math.min(3, n - keepEnd);
        String prefix = phone.substring(0, prefixLen);
        String suffix = phone.substring(n - keepEnd);
        return prefix + "****" + suffix;
    }

    private int satisfactionPercentAllTime(String volunteerId, User user) {
        Double avg = reviewMapper.avgRatingByRevieweeId(volunteerId);
        if (avg != null && avg > 0) {
            return ratingToPercent(avg);
        }
        if (user != null && user.getRating() != null) {
            return (int) Math.round(user.getRating() * 20.0);
        }
        return 0;
    }

    private Double computeDistanceKm(HelpRequest r, Double vLat, Double vLng) {
        if (r.getLatitude() == null || r.getLongitude() == null || vLat == null || vLng == null) {
            return null;
        }
        return AmapService.distanceKm(r.getLongitude(), r.getLatitude(), vLng, vLat);
    }

    private int computeDispatchMatchScore(HelpRequest r, List<String> skillCodes,
                                          Double vLat, Double vLng, User volunteer) {
        boolean matched = skillMatches(skillCodes, r.getType());
        int skillPts = matched ? 44 : 12;
        int distPts;
        if (r.getLatitude() != null && r.getLongitude() != null && vLat != null && vLng != null) {
            double distKm = AmapService.distanceKm(
                    r.getLongitude(), r.getLatitude(), vLng, vLat);
            distPts = (int) Math.round(28 * Math.max(0, 1 - Math.min(1, distKm / 14.0)));
        } else {
            distPts = 14;
        }
        String u = r.getUrgency() != null ? r.getUrgency() : "low";
        int urgPts;
        switch (u) {
            case "emergency":
                urgPts = 22;
                break;
            case "high":
                urgPts = 15;
                break;
            case "medium":
                urgPts = 8;
                break;
            default:
                urgPts = 4;
        }
        if ("emergency".equals(r.getType())) {
            urgPts = Math.max(urgPts, 20);
        }
        int perfPts = 6;
        if (volunteer.getRating() != null) {
            perfPts = (int) Math.round(Math.min(12, volunteer.getRating() / 5.0 * 12));
        }
        return Math.min(100, skillPts + distPts + urgPts + perfPts);
    }

    private static DispatchScoredRequestDto toDispatchScoredDto(HelpRequest r, int score,
                                                                Double distKm, boolean skillMatched) {
        DispatchScoredRequestDto d = new DispatchScoredRequestDto();
        d.setRequestId(r.getId());
        d.setType(r.getType());
        d.setTypeLabel(requestTypeLabel(r.getType()));
        d.setTitle(r.getTitle());
        d.setDescription(r.getDescription());
        d.setSeekerName(r.getUserName());
        d.setLocation(r.getLocation());
        d.setUrgency(r.getUrgency());
        d.setEmergency("emergency".equals(r.getUrgency()) || "emergency".equals(r.getType()));
        if (r.getCreatedAt() != null) {
            d.setCreatedAt(DateTimeFormatter.ISO_LOCAL_DATE_TIME.format(r.getCreatedAt()));
        } else {
            d.setCreatedAt("");
        }
        d.setMatchScore(score);
        d.setDistanceKm(distKm);
        d.setSkillMatched(skillMatched);
        return d;
    }
}
